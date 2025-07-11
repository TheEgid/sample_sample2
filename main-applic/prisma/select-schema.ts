/* eslint-disable @typescript-eslint/naming-convention */
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const isWindows = process.platform === "win32";

async function selectSchema(): Promise<void> {
    try {
        const schema = isWindows ? "schema.sqlite-prisma" : "schema.postgresql-prisma";
        const prismaDir = path.resolve(__dirname, "../prisma");
        const source = path.join(prismaDir, schema);
        const target = path.join(prismaDir, "schema.prisma");

        try {
            await fs.access(target);
            // await fs.unlink(target);
            // console.log(`Файл ${target} удалён перед копированием.`);
        } catch {
            // Если файла нет — ничего не делаем
        }

        console.log(`⏳ Выбор схемы: ${schema}`);
        await fs.copyFile(source, target);
        console.log("✅ Схема скопирована успешно.");
    }
    catch (err) {
        console.error("❌ Ошибка выбора схемы:", err);
        process.exit(1);
    }
}

void selectSchema();
