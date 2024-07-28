import bcrypt from "bcryptjs";
import mongoose, { Schema, ObjectId } from "mongoose";
import { dbConnect } from "../config/dbConnect";
import { User, IUser } from "../models/user.model";
import {
  TaskBoard,
  ITaskBoard,
  TaskStatus,
  TaskPriority,
} from "../models/taskBoard.model";

const saltRounds = 10;

const users: Partial<IUser>[] = [
  {
    name: "Alice Johnson",
    email: "alice.johnson@example.com",
    password: bcrypt.hashSync("password123", saltRounds),
  },
  {
    name: "Bob Smith",
    email: "bob.smith@example.com",
    password: bcrypt.hashSync("password123", saltRounds),
  },
];

const taskBoards: Partial<ITaskBoard>[] = [
  {
    userId: undefined, // Will be set after creating users
    tasks: [
      {
        title: "Implement User Authentication",
        description:
          "Develop and integrate user authentication using email and password.",
        status: TaskStatus.TODO,
        priority: TaskPriority.URGENT,
        deadline: new Date("2024-08-15"),
      },
      {
        title: "Design Home Page UI",
        description:
          "Develop and integrate user authentication using email and password.",
        status: TaskStatus.IN_PROGRESS,
        priority: TaskPriority.MEDIUM,
        deadline: new Date("2024-08-15"),
      },
    ],
  },
];

const seedData = async () => {
  try {
    await dbConnect();

    // Clean up existing data
    await Promise.all([User.deleteMany({}), TaskBoard.deleteMany({})]);

    // Insert users
    const createdUsers = await User.insertMany(users as IUser[]);

    // Assign userId to task boards
    taskBoards.forEach((board, index) => {
      board.userId = createdUsers[index]._id as ObjectId;
    });

    // Insert task boards
    await TaskBoard.insertMany(taskBoards as ITaskBoard[]);

    console.log("Data seeded successfully");
    process.exit(0);
  } catch (err) {
    console.error("Error seeding data:", err);
    process.exit(1);
  }
};

(async () => {
  await seedData();
})();
