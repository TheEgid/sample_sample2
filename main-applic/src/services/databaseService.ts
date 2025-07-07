import dotenv from "dotenv";
import { PrismaClient, type User } from "../../prisma/generated/prisma-client/client";

dotenv.config();

export type IUser = User;

declare global {
    var prisma: PrismaClient | undefined;
}

const isWindows = process.platform === "win32";

const DATABASE_URL = isWindows
    ? "file:./../prisma/database-sql-lite.db"
    : process.env.DATABASE_URL;

if (!DATABASE_URL) {
    throw new Error(
        "DATABASE_URL is not set. Make sure your environment variables are configured correctly in .env",
    );
}

const prisma = global.prisma ?? new PrismaClient({
    datasources: {
        db: {
            url: DATABASE_URL,
        },
    },
    log: ["warn", "error", "info", "query"],
});

if (process.env.NODE_ENV === "development") {
    global.prisma = prisma;
}

export default prisma;
