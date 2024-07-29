import { Request, Response, NextFunction } from "express";
import { CatchAsyncError } from "../middleware/catchAsyncError";
import { TaskBoard } from "../models/taskBoard.model";
import { ErrorHandler } from "../utils/ErrorHandler";

// Create Task Board
export const createTaskBoard = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { userId, tasks } = req.body;

      if (!userId || !tasks) {
        return next(
          new ErrorHandler("Please provide all required fields", 400)
        );
      }

      const taskBoard = await TaskBoard.create({ userId, tasks });

      return res.status(201).json({
        success: true,
        taskBoard,
      });
    } catch (error) {
      return next(new ErrorHandler(error, 400));
    }
  }
);

// Get Task Board by User ID
export const getTaskBoardByUserId = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { userId } = req.params;

      const taskBoard = await TaskBoard.findOne({ userId });

      if (!taskBoard) {
        return next(new ErrorHandler("Task board not found", 404));
      }

      return res.status(200).json({
        success: true,
        taskBoard,
      });
    } catch (error) {
      return next(new ErrorHandler(error, 400));
    }
  }
);

// Update Task Board
export const updateTaskBoard = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    try {
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

      return res.status(200).json({
        success: true,
        taskBoard,
      });
    } catch (error) {
      return next(new ErrorHandler(error, 400));
    }
  }
);

// Delete Task Board
export const deleteTask = CatchAsyncError(
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { userId, taskId } = req.params;

      const taskBoard = await TaskBoard.findOne({ userId });

      if (!taskBoard) {
        return next(new ErrorHandler("Task board not found", 404));
      }

      const taskIndex = taskBoard.tasks.findIndex(
        (task) => task._id.toString() === taskId
      );

      if (taskIndex === -1) {
        return next(new ErrorHandler("Task not found", 404));
      }

      taskBoard.tasks.splice(taskIndex, 1);
      await taskBoard.save();

      return res.status(200).json({
        success: true,
        message: "Task deleted successfully",
      });
    } catch (error) {
      return next(new ErrorHandler(error, 400));
    }
  }
);
