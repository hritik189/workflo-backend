import { app } from "./src/app/app";
import { port } from "./src/config/config";
import { dbConnect } from "./src/config/dbConnect";
import dotenv from "dotenv";

dotenv.config();

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
  dbConnect();
});
