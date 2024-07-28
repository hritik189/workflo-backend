import express from "express";
import { authRouter } from "./auth.routes";
import { taskBoardRouter } from "./taskBoard.routes";

export const router = express.Router();

router.use("/auth", authRouter);
router.use("/task-board", taskBoardRouter);
