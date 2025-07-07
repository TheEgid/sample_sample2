import dotenv from "dotenv";
import { PrismaClient, type User } from "../../prisma/generated/prisma-client/client";

dotenv.config();

export type IUser = User;

declare global {
    // Чтобы при хот-релоаде не создавать новый клиент
    // (важно в dev-среде)
    var prisma: PrismaClient | undefined;
}

const isWindows = process.platform === "win32";

// В Windows жестко указываем SQLite URL с file: префиксом
// В Linux берем из env — там должен быть postgresql://...
const DATABASE_URL = isWindows
    ? "file:./../prisma/database-sql-lite.db"
    : process.env.DATABASE_URL;

if (!DATABASE_URL) {
    throw new Error(
        "DATABASE_URL не задана. Убедитесь, что переменные окружения заданы корректно в .env",
    );
}

// При использовании PrismaClient можно передать URL вручную,
// чтобы он не читал из env напрямую
const prisma = global.prisma ?? new PrismaClient({
    datasources: {
        db: {
            url: DATABASE_URL,
        },
    },
    log: ["warn", "error", "info", "query"],
});

// В development сохраняем экземпляр глобально для hot reload
if (process.env.NODE_ENV === "development") {
    global.prisma = prisma;
}

export default prisma;
