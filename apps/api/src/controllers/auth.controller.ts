import { NextFunction, Request, Response } from "express";
import { CatchAsyncError } from "../middleware/catchAsyncError";
import { User, IUser } from "../models/user.model";
import { ErrorHandler } from "../utils/ErrorHandler";
import { generateToken } from "../utils/jwt";

// Signup Controller
export const signupUser = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const { name, email, password } = req.body;
      console.log(name, email, password);
    if (!name || !email || !password) {
      return next(new ErrorHandler("Please provide all required fields", 400));
    }

    const userExists = await User.findOne({ email });

    if (userExists) {
      return next(new ErrorHandler("User already exists", 400));
    }

    const user = await User.create({ name, email, password });

    const access_token = generateToken(user._id);

    res.cookie("access_token", access_token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    res.status(201).json({
      success: true,
      message: "Signup successful",
      access_token,
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  }
);

// Login Controller
export const loginUser = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return next(new ErrorHandler("Please provide email and password", 400));
    }

    const user = await User.findOne({ email }).select("+password");
    if (!user) {
      return next(new ErrorHandler("Invalid credentials", 401));
    }

    const isPasswordMatch = await user.comparePassword(password);
    if (!isPasswordMatch) {
      return next(new ErrorHandler("Invalid credentials", 401));
    }

    const access_token = generateToken(user._id);

    res.cookie("access_token", access_token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 7 * 24 * 60 * 60 * 1000,
    });

    return res.status(200).json({
      success: true,
      message: "Login successful",
      access_token,
    });
  }
);

// Validate Session Controller
export const validateSession = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const user = req.user as IUser;

    if (!user) {
      return next(new ErrorHandler("No data found in the session", 401));
    }

    return res.status(200).json({
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  }
);

// Logout Controller
export const logoutUser = (req: Request, res: Response, next: NextFunction) => {
  try {
    res.clearCookie("access_token", {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
    });

    return res.status(200).json({
      success: true,
      message: "Logout successful",
    });
  } catch (error) {
    return next(new ErrorHandler(error, 500));
  }
};
