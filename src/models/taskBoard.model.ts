import { Schema, Document, model, Model } from "mongoose";

export enum TaskStatus {
  TODO = "To-Do",
  IN_PROGRESS = "In Progress",
  UNDER_REVIEW = "Under Review",
  COMPLETED = "Completed",
}

export enum TaskPriority {
  LOW = "Low",
  MEDIUM = "Medium",
  URGENT = "Urgent",
}

export interface ITask {
  _id: Schema.Types.ObjectId;
  title: string;
  description?: string;
  status: TaskStatus;
  priority?: TaskPriority;
  deadline?: Date;
}

export interface ITaskBoard extends Document {
  userId: Schema.Types.ObjectId;
  tasks: ITask[];
  createdAt: Date;
  updatedAt: Date;
}

const taskSchema = new Schema<ITask>({
  _id: { type: Schema.Types.ObjectId, auto: true },
  title: { type: String, required: true },
  description: { type: String },
  status: {
    type: String,
    enum: Object.values(TaskStatus),
    required: true,
  },
  priority: {
    type: String,
    enum: Object.values(TaskPriority),
  },
  deadline: { type: Date },
});

const taskBoardSchema = new Schema<ITaskBoard>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    tasks: [taskSchema],
  },
  { timestamps: true }
);

export const TaskBoard: Model<ITaskBoard> = model<ITaskBoard>(
  "TaskBoard",
  taskBoardSchema
);
