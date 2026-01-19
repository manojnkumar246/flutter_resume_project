import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";

const REQUESTS_KEY = "profileChangeRequests";

async function createRequest(req, res) {
  try {
    const id = uuidv4();
    const doc = {
      id,
      ...req.body,
      status: "pending",
      createdAt: new Date().toISOString(),
    };

    await redisClient.hSet(REQUESTS_KEY, id, JSON.stringify(doc));
    res.status(201).json({ id });
  } catch (error) {
    res.status(500).json({ error: "Failed to create profile change request." });
  }
}

async function listRequests(req, res) {
  try {
    const requests = await redisClient.hGetAll(REQUESTS_KEY);
    res.json(Object.values(requests).map((r) => JSON.parse(r)));
  } catch (error) {
    res.status(500).json({ error: "Failed to retrieve profile change requests." });
  }
}

async function getEmployeeRequests(req, res) {
    try {
      const { employeeId } = req.params;
      const requests = await redisClient.hGetAll(REQUESTS_KEY);
      const employeeRequests = Object.values(requests)
        .map((r) => JSON.parse(r))
        .filter((r) => r.employeeId === employeeId);
      res.json(employeeRequests);
    } catch (error) {
      res.status(500).json({ error: "Failed to retrieve employee profile change requests." });
    }
  }

async function getRequest(req, res) {
  try {
    const { id } = req.params;
    const request = await redisClient.hGet(REQUESTS_KEY, id);
    if (request) {
      res.json(JSON.parse(request));
    } else {
      res.status(404).json({ error: "Profile change request not found." });
    }
  } catch (error) {
    res.status(500).json({ error: "Failed to retrieve profile change request." });
  }
}

async function approveRequest(req, res) {
  try {
    const { id } = req.params;
    const requestString = await redisClient.hGet(REQUESTS_KEY, id);
    if (!requestString) {
      return res.status(404).json({ error: "Request not found." });
    }

    const request = JSON.parse(requestString);
    
    // Hypothetical: Update main profile logic would go here
    // For now, we just update the status.
    const updatedRequest = { ...request, status: "approved" };

    await redisClient.hSet(REQUESTS_KEY, id, JSON.stringify(updatedRequest));
    res.json(updatedRequest);
  } catch (error) {
    res.status(500).json({ error: "Failed to approve request." });
  }
}

async function rejectRequest(req, res) {
  try {
    const { id } = req.params;
    const requestString = await redisClient.hGet(REQUESTS_KEY, id);
    if (!requestString) {
      return res.status(404).json({ error: "Request not found." });
    }

    const request = JSON.parse(requestString);
    const updatedRequest = { ...request, status: "rejected" };

    await redisClient.hSet(REQUESTS_KEY, id, JSON.stringify(updatedRequest));
    res.json(updatedRequest);
  } catch (error) {
    res.status(500).json({ error: "Failed to reject request." });
  }
}

async function deleteRequest(req, res) {
  try {
    const { id } = req.params;
    await redisClient.hDel(REQUESTS_KEY, id);
    res.status(204).send();
  } catch (error) {
    res.status(500).json({ error: "Failed to delete request." });
  }
}

export default {
  createRequest,
  listRequests,
  getEmployeeRequests,
  getRequest,
  approveRequest,
  rejectRequest,
  deleteRequest,
};