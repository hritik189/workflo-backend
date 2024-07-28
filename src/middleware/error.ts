import { NextFunction, Request, Response } from "express";
import { ErrorHandler } from "../utils/ErrorHandler";

export const ErrorMiddleware = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  err.statusCode = err.statusCode || 500;
  err.message = err.message || "Internal Server Error";

  // Handle specific error types
  switch (err.name) {
    case "CastError":
      const message = `Resource not found: ${err.path}`;
      err = new ErrorHandler(message, 400);
      break;
    case 11000:
      const duplicateMessage = `Duplicate ${Object.keys(err.keyValue)} entered`;
      err = new ErrorHandler(duplicateMessage, 400);
      break;
    case "JsonWebTokenError":
      err = new ErrorHandler(
        "Json web token is invalid, please try again",
        400
      );
      break;
    case "TokenExpiredError":
      err = new ErrorHandler("Token has expired, please login again", 400);
      break;
    default:
      break;
  }

  // Default error handling
  res.status(err.statusCode).json({
    message: err.message,
  });
};
