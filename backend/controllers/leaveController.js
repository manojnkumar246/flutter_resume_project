import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";

const LEAVES_KEY = "leaves";

async function createLeave(req, res) {
  try {
    const payload = req.body;

    if (!payload || !payload.employeeName || !payload.leaveType || !payload.startDate || !payload.endDate) {
      return res.status(400).json({ error: "Missing required leave information." });
    }

    const id = uuidv4();
    const timestamp = new Date().toISOString();
    const leaveDoc = {
      id,
      createdAt: timestamp,
      status: "pending", // Initial status
      ...payload,
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(leaveDoc));

    res.status(201).json({ id, createdAt: timestamp });
  } catch (err) {
    console.error("Error saving leave form:", err);
    res.status(500).json({ error: "Failed to save leave form." });
  }
}

async function listLeaves(req, res) {
  try {
    const leaves = await redisClient.hGetAll(LEAVES_KEY);
    const result = Object.values(leaves).map((l) => {
      const data = JSON.parse(l);
      return {
        id: data.id,
        employeeName: data.employeeName || "Unnamed",
        leaveType: data.leaveType,
        startDate: data.startDate,
        endDate: data.endDate,
        status: data.status,
        createdAt: data.createdAt,
      };
    });
    res.json(result);
  } catch (err) {
    console.error("Error listing leaves:", err);
    res.status(500).json({ error: "Failed to list leaves." });
  }
}

async function getLeave(req, res) {
  try {
    const { id } = req.params;
    const record = await redisClient.hGet(LEAVES_KEY, id);

    if (!record) {
      return res.status(404).json({ error: "Leave form not found." });
    }

    res.setHeader("Content-Type", "application/json");
    res.send(record);
  } catch (err) {
    console.error("Error reading leave form:", err);
    res.status(500).json({ error: "Failed to read leave form." });
  }
}

async function updateLeaveStatus(id, status) {
  const record = await redisClient.hGet(LEAVES_KEY, id);
  if (!record) {
    return null;
  }
  const existingLeave = JSON.parse(record);
  const updatedLeave = {
    ...existingLeave,
    status,
    updatedAt: new Date().toISOString(),
  };
  await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));
  return updatedLeave;
}

async function approveLeave(req, res) {
  try {
    const { id } = req.params;
    const updatedLeave = await updateLeaveStatus(id, "approved");

    if (!updatedLeave) {
      return res.status(404).json({ error: "Leave form not found." });
    }
    res.status(200).json({ id, updatedAt: updatedLeave.updatedAt, status: updatedLeave.status });
  } catch (err) {
    console.error("Error approving leave:", err);
    res.status(500).json({ error: "Failed to approve leave." });
  }
}

async function denyLeave(req, res) {
  try {
    const { id } = req.params;
    const updatedLeave = await updateLeaveStatus(id, "denied");

    if (!updatedLeave) {
      return res.status(404).json({ error: "Leave form not found." });
    }
    res.status(200).json({ id, updatedAt: updatedLeave.updatedAt, status: updatedLeave.status });
  } catch (err) {
    console.error("Error denying leave:", err);
    res.status(500).json({ error: "Failed to deny leave." });
  }
}

async function updateLeave(req, res) {
  try {
    const { id } = req.params;
    const payload = req.body; // Expecting { status: 'approved' | 'denied' } or full form update

    const record = await redisClient.hGet(LEAVES_KEY, id);
    if (!record) {
      return res.status(404).json({ error: "Leave form not found." });
    }

    const existingLeave = JSON.parse(record);

    // If only status is provided, just update that. Otherwise, update the whole form.
    const updatedLeave = {
      ...existingLeave,
      ...payload,
      updatedAt: new Date().toISOString(),
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));
    res.status(200).json({ id, updatedAt: updatedLeave.updatedAt, status: updatedLeave.status });
  } catch (err) {
    console.error("Error updating leave form:", err);
    res.status(500).json({ error: "Failed to update leave form." });
  }
}

async function deleteLeave(req, res) {
  try {
    const { id } = req.params;
    const exists = await redisClient.hExists(LEAVES_KEY, id);

    if (!exists) {
      return res.status(404).json({ error: "Leave form not found." });
    }

    await redisClient.hDel(LEAVES_KEY, id);
    res.status(200).json({ message: "Leave form deleted successfully." });
  } catch (err) {
    console.error("Error deleting leave form:", err);
    res.status(500).json({ error: "Failed to delete leave form." });
  }
}

export default { createLeave, listLeaves, getLeave, updateLeave, deleteLeave, approveLeave, denyLeave };