import { Request, Response, NextFunction } from "express";
import { CatchAsyncError } from "../middleware/catchAsyncError";
import { TaskBoard } from "../models/taskBoard.model";
import { ErrorHandler } from "../utils/ErrorHandler";

// Create Task Board
export const createTaskBoard = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const { userId, tasks } = req.body;

    if (!userId || !tasks) {
      return next(new ErrorHandler("Please provide all required fields", 400));
    }

    const taskBoard = await TaskBoard.create({ userId, tasks });

    res.status(201).json({
      success: true,
      taskBoard,
    });
  }
);

// Get Task Board by User ID
export const getTaskBoardByUserId = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = req.params;

    const taskBoard = await TaskBoard.findOne({ userId });

    if (!taskBoard) {
      return next(new ErrorHandler("Task board not found", 404));
    }

    res.status(200).json({
      success: true,
      taskBoard,
    });
  }
);

// Update Task Board
export const updateTaskBoard = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = req.params;
    const { tasks } = req.body;

    const taskBoard = await TaskBoard.findOneAndUpdate(
      { userId },
      { tasks },
      { new: true, runValidators: true }
    );

    if (!taskBoard) {
      return next(new ErrorHandler("Task board not found", 404));
    }

    res.status(200).json({
      success: true,
      taskBoard,
    });
  }
);

// Delete Task Board
export const deleteTaskBoard = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = req.params;

    const taskBoard = await TaskBoard.findOneAndDelete({ userId });

    if (!taskBoard) {
      return next(new ErrorHandler("Task board not found", 404));
    }

    res.status(200).json({
      success: true,
      message: "Task board deleted successfully",
    });
  }
);
