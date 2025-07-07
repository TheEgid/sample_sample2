import fs from "fs/promises";
import path from "path";

async function selectSchema(): Promise<boolean> {
    try {
        const isWindows = process.platform === "win32";

        console.log(`OS: ${process.platform}, selecting ${isWindows ? "SQLite" : "PostgreSQL"} schema`);

        const prismaDir = path.resolve(__dirname, "../prisma");

        console.log(`Prisma directory: ${prismaDir}`);

        const sourceFile = isWindows
            ? path.join(prismaDir, "schema.sqlite-prisma")
            : path.join(prismaDir, "schema.postgresql-prisma");

        const targetFile = path.join(prismaDir, "schema.prisma");

        console.log(`Copying from ${sourceFile} to ${targetFile}`);

        await fs.copyFile(sourceFile, targetFile);
        console.log("✅ Schema copied successfully");

        return true;
    }
    catch (error) {
        console.error("❌ Error selecting schema:", error);
        process.exit(1);
    }
}

void selectSchema();
