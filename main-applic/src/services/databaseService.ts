import dotenv from "dotenv";
import { type User, PrismaClient } from "../../prisma/generated/prisma-client/client";

export type IUser = User;

declare global {
    var prisma: PrismaClient | undefined;
}

dotenv.config();

const DATABASE_URL = "file:./../prisma/database-sql-lite.db";

const prisma = new PrismaClient({
    datasources: { db: { url: DATABASE_URL } },
    log: ["warn", "error", "info", "query"],
});

if (process.env.NODE_ENV === "development") {
    global.prisma = prisma;
}

export default prisma;
