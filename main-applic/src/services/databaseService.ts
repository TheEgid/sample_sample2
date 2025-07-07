import dotenv from "dotenv";
import { PrismaClient, type User } from "../../prisma/generated/prisma-client/client";

dotenv.config();

export type IUser = User;

const DATABASE_URL = process.platform === "win32"
    ? "file:./../prisma/database-sql-lite.db"
    : process.env.DATABASE_URL;

if (!DATABASE_URL) {
    throw new Error("DATABASE_URL не задан. Проверь .env");
}

const prisma = new PrismaClient({
    datasources: { db: { url: DATABASE_URL } },
    log: ["warn", "error", "info", "query"],
});

export default prisma;
