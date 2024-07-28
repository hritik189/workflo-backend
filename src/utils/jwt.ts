import jwt from "jsonwebtoken";
import { jwtSecret } from "../config/config";

export const generateToken = (id: any) => {
  return jwt.sign({ id }, jwtSecret, { expiresIn: "7d" });
};
