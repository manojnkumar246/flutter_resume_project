import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";

const LEAVES_KEY = "leaves";

async function createLeave(req, res) {
  try {
    const id = uuidv4();
    const doc = { id, ...req.body, status: "pending", createdAt: new Date().toISOString() };
    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(doc));
    res.status(201).json({ id });
  } catch {
    res.status(500).json({ error: "Leave creation failed." });
  }
}

async function listLeaves(req, res) {
  const leaves = await redisClient.hGetAll(LEAVES_KEY);
  res.json(Object.values(leaves).map(l => JSON.parse(l)));
}

async function getLeave(req, res) {
    try {
      const { id } = req.params;
      const leave = await redisClient.hGet(LEAVES_KEY, id);
      if (leave) {
        res.json(JSON.parse(leave));
      } else {
        res.status(404).json({ error: "Leave not found." });
      }
    } catch (error) {
      res.status(500).json({ error: "Failed to retrieve leave." });
    }
  }
  
  async function updateLeave(req, res) {
    try {
      const { id } = req.params;
      const leaveString = await redisClient.hGet(LEAVES_KEY, id);
      if (!leaveString) {
        return res.status(404).json({ error: "Leave not found." });
      }
  
      const leave = JSON.parse(leaveString);
      const updatedLeave = { ...leave, ...req.body };
  
      await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));
      res.json(updatedLeave);
    } catch (error) {
      res.status(500).json({ error: "Failed to update leave." });
    }
  }
  
  async function deleteLeave(req, res) {
    try {
      const { id } = req.params;
      await redisClient.hDel(LEAVES_KEY, id);
      res.status(204).send();
    } catch (error) {
      res.status(500).json({ error: "Failed to delete leave." });
    }
  }

export default { createLeave, listLeaves, getLeave, updateLeave, deleteLeave };