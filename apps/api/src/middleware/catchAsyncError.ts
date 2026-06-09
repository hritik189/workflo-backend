import { NextFunction, Request, Response } from "express";

export const CatchAsyncError = (
  theFunction: (req: Request, res: Response, next: NextFunction) => Promise<any>
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    theFunction(req, res, next).catch((err) => {
      console.error("Async error caught:", err);
      next(err);
    });
  };
};
