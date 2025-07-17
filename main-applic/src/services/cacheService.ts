import dotenv from "dotenv";
import Redis from "ioredis";
import NodeCache from "node-cache";

dotenv.config();

const isWindows = process.platform === "win32";

let redisClient: Redis | null = null;

if (!isWindows) {
    redisClient = new Redis(process.env.REDIS_URL ?? undefined);
    redisClient.on("error", (err) => {
        console.error("Redis error:", err);
    });
}

const localCache = new NodeCache();

export const cacheGet = async <T = any>(key: string): Promise<T | null> => {
    if (!isWindows && redisClient) {
        const data = await redisClient.get(key);

        if (!data) { return null; }
        try {
            return JSON.parse(data) as T;
        }
        catch (error) {
            console.error(`cacheGet JSON.parse error for key "${key}":`, error);
            return null;
        }
    }
    else {
        return localCache.get<T>(key) || null;
    }
};

export const cacheSet = async (key: string, value: any, ttlSeconds = 259200): Promise<void> => {
    if (!isWindows && redisClient) {
        try {
            await redisClient.set(key, JSON.stringify(value), "EX", ttlSeconds);
        }
        catch (error) {
            console.error(`cacheSet error for key "${key}":`, error);
        }
    }
    else {
        localCache.set(key, value, ttlSeconds);
    }
};
