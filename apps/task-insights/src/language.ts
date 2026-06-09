import { TextAnalysisClient } from "@azure/ai-language-text";
import { AzureKeyCredential } from "@azure/core-auth";

const endpoint = process.env.AI_LANGUAGE_ENDPOINT;
const apiKey = process.env.AI_LANGUAGE_KEY;

// Readiness gate: the service can only serve /insights when its upstream is configured.
export function isConfigured(): boolean {
  return Boolean(endpoint && apiKey);
}

let client: TextAnalysisClient | null = null;

function getClient(): TextAnalysisClient {
  if (!client) {
    if (!endpoint || !apiKey) {
      throw new Error("AI_LANGUAGE_ENDPOINT and AI_LANGUAGE_KEY must be set");
    }
    client = new TextAnalysisClient(endpoint, new AzureKeyCredential(apiKey));
  }
  return client;
}

export interface TaskInsights {
  sentiment: string;
  confidenceScores: { positive: number; neutral: number; negative: number };
  keyPhrases: string[];
}

// Runs sentiment analysis and key-phrase extraction over a single document.
export async function analyzeText(text: string): Promise<TaskInsights> {
  const c = getClient();

  const [sentimentResults, keyPhraseResults] = await Promise.all([
    c.analyze("SentimentAnalysis", [text]),
    c.analyze("KeyPhraseExtraction", [text]),
  ]);

  const sentiment = sentimentResults[0];
  const keyPhrase = keyPhraseResults[0];

  // Truthiness check narrows the success/error result union under strict TS.
  if (sentiment.error) {
    throw new Error(`Sentiment analysis failed: ${sentiment.error.message}`);
  }
  if (keyPhrase.error) {
    throw new Error(`Key phrase extraction failed: ${keyPhrase.error.message}`);
  }

  return {
    sentiment: sentiment.sentiment,
    confidenceScores: sentiment.confidenceScores,
    keyPhrases: keyPhrase.keyPhrases,
  };
}
