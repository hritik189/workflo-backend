import cors from "cors";
import express, { NextFunction, Request, Response } from "express";
import { origin } from "../config/config";
import { router as ApiRoutes } from "../routes/index.routes";
import morgan from "morgan";
import { ErrorMiddleware } from "../middleware/error";
import cookieParser from "cookie-parser";
import mongoose from "mongoose";

export const app = express();

// cookie parser
app.use(cookieParser());

// Loggin Http requests
app.use(morgan("dev"));

// body parser
app.use(express.json({ limit: "50mb" }));

//cors
app.use(
  cors({
    origin: ["http://localhost:3000", "http://localhost:5173"],
    credentials: true,
  })
);

//  api routes
app.use("/api/", ApiRoutes);

// test route
app.get("/api/test", (req: Request, res: Response, next: NextFunction) => {
  return res.status(200).json({
    message: "Api is working",
  });
});

// Liveness probe — process is up and serving (Kubernetes livenessProbe).
// Always 200 while the event loop is responsive; does NOT depend on the DB,
// so a transient DB outage won't cause pods to be killed and restarted.
app.get("/health", (req: Request, res: Response) => {
  return res.status(200).json({ status: "ok", uptime: process.uptime() });
});

// Readiness probe — dependencies are reachable (Kubernetes readinessProbe).
// Returns 503 when MongoDB is not connected so the pod is pulled from the
// Service load-balancer until it can actually serve requests.
app.get("/ready", (req: Request, res: Response) => {
  const dbConnected = mongoose.connection.readyState === 1;
  return res.status(dbConnected ? 200 : 503).json({
    status: dbConnected ? "ready" : "not-ready",
    db: dbConnected ? "connected" : "disconnected",
  });
});

// unknown api request
app.all("*", (req: Request, res: Response, next: NextFunction) => {
  const err = new Error(`Can't find ${req.originalUrl} on this server!`) as any;
  err.statusCode = 404;
  next(err);
});

// middleware
app.use(ErrorMiddleware);
