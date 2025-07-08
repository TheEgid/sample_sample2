import dotenv from "dotenv";
import { type User, PrismaClient } from "../../prisma/generated/prisma-client/client";

export type IUser = User;

dotenv.config();

// const DATABASE_URL = process.env.DATABASE_URL_DEV || "";
const DATABASE_URL = process.platform === "win32"
    ? "file:./../prisma/database-sql-lite.db"
    : process.env.DATABASE_URL;

if (!DATABASE_URL) { throw new Error("DATABASE_URL не задан. Проверь .env"); }

const prisma = new PrismaClient({
    datasources: { db: { url: DATABASE_URL } },
    log: ["warn", "error", "info", "query"],
    // log: process.env.NODE_ENV === "development" ? ["warn", "error", "info", "query"] : ["error"],
    // log: ["error"],
});

if (process.env.NODE_ENV === "development") {
    (global as any).prisma = prisma;
}

export default prisma;
