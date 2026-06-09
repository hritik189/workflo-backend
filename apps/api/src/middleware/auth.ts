import { NextFunction, Request, Response } from "express";
import jwt, { JwtPayload } from "jsonwebtoken";
import { jwtSecret } from "../config/config";
import { User, IUser } from "../models/user.model";
import { ErrorHandler } from "../utils/ErrorHandler";
import { CatchAsyncError } from "./catchAsyncError";

interface CustomRequest extends Request {
  user?: IUser;
}

// isAuthenticated middleware
export const isAuthenticated = CatchAsyncError(
  async (req: CustomRequest, res: Response, next: NextFunction) => {
    const access_token = req.cookies.access_token;

    if (!access_token) {
      return next(
        new ErrorHandler("Please login to access this resource", 401)
      );
    }

    try {
      const decoded = jwt.verify(access_token, jwtSecret) as JwtPayload;

      if (!decoded || !decoded.id) {
        return next(new ErrorHandler("Access token is not valid", 400));
      }

      const user = await User.findById(decoded.id).select("+password");

      if (!user) {
        return next(new ErrorHandler("User not found", 404));
      }

      req.user = user;
      next();
    } catch (err) {
      console.error("Authentication error:", err);
      return next(new ErrorHandler("Failed to authenticate", 500));
    }
  }
);
