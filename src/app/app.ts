import cors from "cors";
import express, { NextFunction, Request, Response } from "express";
import { origin } from "../config/config";
import { router as ApiRoutes } from "../routes/index.routes";
import morgan from "morgan";
import { ErrorMiddleware } from "../middleware/error";
import cookieParser from "cookie-parser";

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

// unknown api request
app.all("*", (req: Request, res: Response, next: NextFunction) => {
  const err = new Error(`Can't find ${req.originalUrl} on this server!`) as any;
  err.status = 404;
  next(err);
});

// middleware
app.use(ErrorMiddleware);
