import { createClient } from "redis";

// Initialize the client
const client = createClient({
  socket: {
    host: "172.26.92.131",
    port: 6379,
  },
});

client.on("error", (err) => console.error("❌ Redis Client Error:", err));
client.on("connect", () => console.log("✅ Connected to Redis"));

// Redis v4+ requires calling .connect() explicitly
await client.connect();

const redisAsync = {
  hGetAll: (key) => client.hGetAll(key),
  hGet: (key, field) => client.hGet(key, field),
  hSet: (key, field, value) => client.hSet(key, field, value),
  hDel: (key, field) => client.hDel(key, field),
};

export default redisAsync;