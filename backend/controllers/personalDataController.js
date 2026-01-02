import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";

// Create a new resume
async function createForm(req, res) {
  try {
    const payload = req.body;
    if (!payload || !payload.name) {
      return res.status(400).json({ error: "Form must include a name field." });
    }

    const id = uuidv4();
    const timestamp = new Date().toISOString();
    const formDoc = { id, createdAt: timestamp, ...payload };

    // Save to Redis hash "resumes" with field = id
    await redisClient.hSet("resumes", id, JSON.stringify(formDoc));

    res.status(201).json({ id, createdAt: timestamp });
  } catch (err) {
    console.error("Error saving form:", err);
    res.status(500).json({ error: "Failed to save form." });
  }
}

// List all resumes
async function listForms(req, res) {
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
}

// Get a single resume by ID
async function getForm(req, res) {
  try {
    const { id } = req.params;
    const record = await redisClient.hGet("resumes", id);

    if (!record) return res.status(404).json({ error: "Form not found." });

    res.setHeader("Content-Type", "application/json");
    res.send(record);
  } catch (err) {
    console.error("Error reading form:", err);
    res.status(500).json({ error: "Failed to read form." });
  }
}

// Update an existing resume by ID
async function updateForm(req, res) {
  try {
    const { id } = req.params;
    const exists = await redisClient.hExists("resumes", id);
    if (!exists) return res.status(404).json({ error: "Form not found." });

    const payload = req.body;
    const timestamp = new Date().toISOString();
    const updatedDoc = { id, updatedAt: timestamp, ...payload };

    await redisClient.hSet("resumes", id, JSON.stringify(updatedDoc));

    res.json({ message: "Resume updated successfully", updatedAt: timestamp });
  } catch (err) {
    console.error("Error updating form:", err);
    res.status(500).json({ error: "Failed to update form." });
  }
}

// Delete a resume by ID
async function deleteForm(req, res) {
  try {
    const { id } = req.params;
    const deleted = await redisClient.hDel("resumes", id);
    if (!deleted) return res.status(404).json({ error: "Form not found." });

    res.json({ message: "Resume deleted successfully" });
  } catch (err) {
    console.error("Error deleting form:", err);
    res.status(500).json({ error: "Failed to delete form." });
  }
}

export default { createForm, listForms, getForm, updateForm, deleteForm };
