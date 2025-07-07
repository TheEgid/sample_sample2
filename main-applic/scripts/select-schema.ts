import fs from "fs/promises";
import path from "path";

async function selectSchema(): Promise<void> {
    const isWindows = process.platform === "win32";
    const prismaDir = path.join(__dirname, "../prisma");

    const sourceFile = isWindows
        ? path.join(prismaDir, "schema.sqlite-prisma")
        : path.join(prismaDir, "schema.postgresql-prisma");

    const targetFile = path.join(prismaDir, "schema.prisma");

    try {
        await fs.copyFile(sourceFile, targetFile);
        console.log(`✅ Schema selected: ${isWindows ? "SQLite" : "PostgreSQL"}`);
    }
    catch (error) {
        console.error("❌ Error selecting schema:", error);
        process.exit(1);
    }
}

void selectSchema();
