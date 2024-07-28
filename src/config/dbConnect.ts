import mongoose from "mongoose";
import { dbUrl } from "./config";

export const dbConnect = async () => {
  try {
    await mongoose
      .connect(dbUrl, {
        dbName: "workflo_DB",
      })
      .then((data) => {
        console.log(`Database connected with ${data.connection.host} `);
      });
  } catch (error: any) {
    console.error(`Error connecting to the database: ${error.message}`);
    setTimeout(dbConnect, 5000);
  }
};
