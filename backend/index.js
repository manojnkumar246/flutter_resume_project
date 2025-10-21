import express from "express";
import cors from "cors";
import personalDataController from "./controllers/personalDataController.js";
import "./config/redisClient.js"; // connects automatically

const app = express();
app.use(cors());
app.use(express.json({ limit: "5mb" }));

// Routes
app.post("/resume", personalDataController.createForm());
app.post("/resumes", personalDataController.createForm());
app.get("/resumes", personalDataController.listForms());
app.get("/resumes/:id", personalDataController.getForm());

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on 0.0.0.0:${PORT}`);
});
