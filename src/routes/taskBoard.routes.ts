import express from "express";
import {
  createTaskBoard,
  getTaskBoardByUserId,
  updateTaskBoard,
  deleteTaskBoard,
} from "../controllers/taskBoard.controller";
import { isAuthenticated } from "../middleware/auth";

export const taskBoardRouter = express.Router();

taskBoardRouter.post("/", isAuthenticated, createTaskBoard);
taskBoardRouter.get("/:userId", isAuthenticated, getTaskBoardByUserId);
taskBoardRouter.put("/:userId", isAuthenticated, updateTaskBoard);
taskBoardRouter.delete("/:userId", isAuthenticated, deleteTaskBoard);