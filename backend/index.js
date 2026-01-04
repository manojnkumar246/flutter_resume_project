import express from "express";
import cors from "cors";
import personalDataController from "./controllers/personalDataController.js";
import leaveController from "./controllers/leaveController.js";
import "./config/redisClient.js"; // connects automatically

const app = express();
app.use(cors());
app.use(express.json({ limit: "5mb" }));

// Personal Data (Resume) Routes
app.post("/resume", personalDataController.createForm);
app.post("/resumes", personalDataController.createForm);
app.get("/resumes", personalDataController.listForms);
app.get("/resumes/:id", personalDataController.getForm);
app.put("/resumes/:id", personalDataController.updateForm);
app.delete("/resumes/:id", personalDataController.deleteForm);

// Change these lines:
app.post("/leaves", leaveController.createLeave);           // Removed /api
app.get("/leaves", leaveController.listLeaves);             // Removed /api
app.get("/leaves/:id", leaveController.getLeave);           // Removed /api
app.put("/leaves/:id", leaveController.updateLeave);


const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on 0.0.0.0:${PORT}`);
});