import { createClient } from "redis";

const redisClient = createClient({
  url: "redis://172.26.92.131:6379" // default local Redis URL
});

redisClient.on("error", (err) => console.error("❌ Redis Client Error:", err));
redisClient.on("connect", () => console.log("✅ Connected to Redis"));

await redisClient.connect();

export default redisClient;
