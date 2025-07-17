import { createHash } from "crypto";
import { cacheGet, cacheSet } from "src/services/cacheService";
import prisma from "src/services/databaseService";
import type { NextApiRequest, NextApiResponse } from "next";

async function checkPostgresConnection(res: NextApiResponse): Promise<void> {
    try {
        const users = await prisma.user.findMany();

        const dataString = JSON.stringify(users);
        const hashed = createHash("sha256").update(dataString).digest("hex");

        let cachedData: any;

        try {
            cachedData = await cacheGet(hashed);
        }
        catch (cacheError) {
            console.error("Cache read error:", cacheError);
        }

        if (cachedData) {
            res.status(200).json(cachedData);
            return;
        }

        try {
            await cacheSet(hashed, users);
        }
        catch (cacheError) {
            console.error("Cache write error:", cacheError);
        }

        res.status(200).json(users);
    }
    catch (error) {
        console.error("Ошибка подключения", error);
        res.status(500).json({ error: "Database error" });
    }
}

// GET /api/database
const handler = async (req: NextApiRequest, res: NextApiResponse): Promise<void> => {
    if (req.method === "GET") {
        await checkPostgresConnection(res);
    }
    else {
        res.status(405).json({ message: "Method not allowed" });
    }
};

export default handler;
