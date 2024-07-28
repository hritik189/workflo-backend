import express from "express";
import {
  signupUser,
  loginUser,
  validateSession,
  logoutUser,
} from "../controllers/auth.controller";
import { isAuthenticated } from "../middleware/auth";

export const authRouter = express.Router();

authRouter.post("/signup", signupUser);
authRouter.post("/login", loginUser);
authRouter.get("/validate", isAuthenticated, validateSession);
authRouter.post("/logout", isAuthenticated, logoutUser);
