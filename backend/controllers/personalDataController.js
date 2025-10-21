import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";

function createForm() {
  return async (req, res) => {
    try {
      const payload = req.body;

      if (!payload || !payload.name) {
        return res.status(400).json({ error: "Form must include a name field." });
      }

      const id = uuidv4();
      const timestamp = new Date().toISOString();
      const formDoc = { id, createdAt: timestamp, ...payload };

      // Save to Redis as JSON string
      await redisClient.hSet("resumes", id, JSON.stringify(formDoc));

      res.status(201).json({ id, createdAt: timestamp });
    } catch (err) {
      console.error("Error saving form:", err);
      res.status(500).json({ error: "Failed to save form." });
    }
  };
}

function listForms() {
  return async (req, res) => {
    try {
      const resumes = await redisClient.hGetAll("resumes");
      const result = Object.values(resumes).map((r) => {
        const data = JSON.parse(r);
        return {
          id: data.id,
          name: data.name || "Unnamed",
          createdAt: data.createdAt,
        };
      });
      res.json(result);
    } catch (err) {
      console.error("Error listing forms:", err);
      res.status(500).json({ error: "Failed to list forms." });
    }
  };
}

function getForm() {
  return async (req, res) => {
    try {
      const { id } = req.params;
      const record = await redisClient.hGet("resumes", id);

      if (!record) {
        return res.status(404).json({ error: "Form not found." });
      }

      res.setHeader("Content-Type", "application/json");
      res.send(record);
    } catch (err) {
      console.error("Error reading form:", err);
      res.status(500).json({ error: "Failed to read form." });
    }
  };
}

export default { createForm, listForms, getForm };
