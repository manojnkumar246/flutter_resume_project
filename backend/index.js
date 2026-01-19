import express from "express";
import cors from "cors";
import personalDataController from "./controllers/personalDataController.js";
import leaveController from "./controllers/leaveController.js";
import authController from "./controllers/authController.js";
import profileChangeController from "./controllers/profileChangeController.js";
import "./config/redisClient.js"; // connects automatically

console.log(profileChangeController);

const app = express();
app.use(cors());
app.use(express.json({ limit: "5mb" }));

// Authentication Routes
app.post("/auth/register", authController.register);
app.post("/auth/login", authController.login);
app.put("/auth/change-password/:id", authController.changePassword);

// Profile Change Request Routes
app.post("/profile-requests", profileChangeController.createRequest);
app.get("/profile-requests", profileChangeController.listRequests);
app.get("/profile-requests/employee/:employeeId", profileChangeController.getEmployeeRequests);
app.get("/profile-requests/:id", profileChangeController.getRequest);
app.put("/profile-requests/:id/approve", profileChangeController.approveRequest);
app.put("/profile-requests/:id/reject", profileChangeController.rejectRequest);
app.delete("/profile-requests/:id", profileChangeController.deleteRequest);

// Personal Data (Resume) Routes
app.post("/resume", personalDataController.createForm);
app.post("/resumes", personalDataController.createForm);
app.get("/resumes", personalDataController.listForms);
app.get("/resumes/:id", personalDataController.getForm);
app.put("/resumes/:id", personalDataController.updateForm);
app.delete("/resumes/:id", personalDataController.deleteForm);

// Leave Routes
app.post("/leaves", leaveController.createLeave);
app.get("/leaves", leaveController.listLeaves);
app.get("/leaves/:id", leaveController.getLeave);
app.put("/leaves/:id", leaveController.updateLeave);
app.delete("/leaves/:id", leaveController.deleteLeave);

const PORT = 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on 0.0.0.0:${PORT}`);
});
