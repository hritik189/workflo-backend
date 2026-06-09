// Must be first: initializes Azure Monitor OpenTelemetry before express/http load.
import "./src/telemetry";
import { app } from "./src/app";
import dotenv from "dotenv";

dotenv.config();

const port = process.env.PORT || 8080;

app.listen(port, () => {
  console.log(`task-insights listening on port ${port}`);
});
