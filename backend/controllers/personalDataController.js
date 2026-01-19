import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";

const FORMS_KEY = "resumes";

async function createForm(req, res) {
  try {
    const id = uuidv4();
    const doc = { id, createdAt: new Date().toISOString(), ...req.body };
    await redisClient.hSet(FORMS_KEY, id, JSON.stringify(doc));
    res.status(201).json({ id });
  } catch (error) {
    res.status(500).json({ error: "Failed to create form." });
  }
}

async function listForms(req, res) {
  try {
    const forms = await redisClient.hGetAll(FORMS_KEY);
    res.json(Object.values(forms).map((f) => JSON.parse(f)));
  } catch (error) {
    res.status(500).json({ error: "Failed to retrieve forms." });
  }
}

async function getForm(req, res) {
  try {
    const { id } = req.params;
    const form = await redisClient.hGet(FORMS_KEY, id);
    if (form) {
      res.json(JSON.parse(form));
    } else {
      res.status(404).json({ error: "Form not found." });
    }
  } catch (error) {
    res.status(500).json({ error: "Failed to retrieve form." });
  }
}

async function updateForm(req, res) {
  try {
    const { id } = req.params;
    const formString = await redisClient.hGet(FORMS_KEY, id);
    if (!formString) {
      return res.status(404).json({ error: "Form not found." });
    }

    const form = JSON.parse(formString);
    const updatedForm = { ...form, ...req.body };

    await redisClient.hSet(FORMS_KEY, id, JSON.stringify(updatedForm));
    res.json(updatedForm);
  } catch (error) {
    res.status(500).json({ error: "Failed to update form." });
  }
}

async function deleteForm(req, res) {
  try {
    const { id } = req.params;
    await redisClient.hDel(FORMS_KEY, id);
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: "Failed to delete form." });
  }
}

export default { createForm, listForms, getForm, updateForm, deleteForm };