import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";
import crypto from "crypto";

function hashPassword(password) {
  return crypto.createHash("sha256").update(password).digest("hex");
}

async function register(req, res) {
  try {
    const payload = req.body;
    if (!payload?.name || !payload.email || !payload.password) {
      return res.status(400).json({ error: "Missing required fields." });
    }

    const users = await redisClient.hGetAll("resumes");
    for (const u of Object.values(users)) {
      const user = JSON.parse(u);
      if (user.email?.toLowerCase() === payload.email.toLowerCase()) {
        return res.status(400).json({ error: "Email already exists." });
      }
    }

    const id = uuidv4();
    const doc = {
      id,
      createdAt: new Date().toISOString(),
      ...payload,
      password: hashPassword(payload.password),
    };

    await redisClient.hSet("resumes", id, JSON.stringify(doc));
    res.status(201).json({ id });
  } catch {
    res.status(500).json({ error: "Registration failed." });
  }
}

async function login(req, res) {
  try {
    const { email, password } = req.body;
    const users = await redisClient.hGetAll("resumes");

    for (const u of Object.values(users)) {
      const user = JSON.parse(u);
      if (user.email?.toLowerCase() === email.toLowerCase()) {
        if (user.password === hashPassword(password)) {
          const { password: _, ...safe } = user;
          return res.json({ message: "Login successful", employee: safe });
        }
      }
    }
    res.status(401).json({ error: "Invalid credentials." });
  } catch {
    res.status(500).json({ error: "Login failed." });
  }
}

async function changePassword(req, res) {
    try {
      const { id } = req.params;
      const { oldPassword, newPassword } = req.body;
  
      const userString = await redisClient.hGet("resumes", id);
      if (!userString) {
        return res.status(404).json({ error: "User not found." });
      }
  
      const user = JSON.parse(userString);
  
      if (user.password !== hashPassword(oldPassword)) {
        return res.status(401).json({ error: "Invalid old password." });
      }
  
      const updatedUser = { ...user, password: hashPassword(newPassword) };
      await redisClient.hSet("resumes", id, JSON.stringify(updatedUser));
  
      res.json({ message: "Password changed successfully." });
    } catch (error) {
      res.status(500).json({ error: "Failed to change password." });
    }
  }

export default { register, login, changePassword };