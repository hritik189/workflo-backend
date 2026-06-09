require("dotenv").config();

export const port = process.env.PORT || 8080;
export const origin = process.env.ORIGIN;
export const dbUrl = process.env.DB_URL!;
export const jwtSecret = process.env.JWT_SECRET!;
export const nodeEnv = process.env.NODE_ENV || "development";
