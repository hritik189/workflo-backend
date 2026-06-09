import express, { Request, Response } from "express";
import { analyzeText, isConfigured } from "./language";

export const app = express();

app.use(express.json({ limit: "1mb" }));

// Liveness — process is up (DB/AI-independent).
app.get("/health", (req: Request, res: Response) => {
  return res.status(200).json({ status: "ok", uptime: process.uptime() });
});

// Readiness — upstream AI Language credentials are configured.
app.get("/ready", (req: Request, res: Response) => {
  const ready = isConfigured();
  return res.status(ready ? 200 : 503).json({ status: ready ? "ready" : "not-ready" });
});

// POST /insights { "text": "..." } -> { sentiment, confidenceScores, keyPhrases }
app.post("/insights", async (req: Request, res: Response) => {
  const { text } = req.body ?? {};
  if (!text || typeof text !== "string") {
    return res.status(400).json({ error: "Body must include a non-empty 'text' string" });
  }

  try {
    const insights = await analyzeText(text);
    return res.status(200).json(insights);
  } catch (err: any) {
    console.error("Insight analysis failed:", err);
    return res.status(502).json({ error: "Upstream AI analysis failed", detail: err.message });
  }
});
