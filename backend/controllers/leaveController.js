import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";
import mailer from "../config/mailer.js";

const ADMIN_EMAIL = "gowtham.b1711@gmail.com";

const LEAVES_KEY = "leaves";

async function createLeave(req, res) {
  try {
    const payload = req.body;

    // Require employeeEmail and basic validation
    if (
      !payload ||
      !payload.employeeName ||
      !payload.leaveType ||
      !payload.startDate ||
      !payload.endDate ||
      !payload.employeeEmail
    ) {
      return res.status(400).json({ error: "Missing required leave information (including employeeEmail)." });
    }

    const email = String(payload.employeeEmail).trim();
    const emailRegex = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Invalid employee email address." });
    }

    const id = uuidv4();
    const timestamp = new Date().toISOString();
    const leaveDoc = {
      id,
      createdAt: timestamp,
      status: "pending",
      ...payload,
      employeeEmail: email,
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(leaveDoc));

    // Prepare action links - use request host
    const baseUrl = req.protocol + '://' + req.get('host');
    const approveLink = `${baseUrl}/leaves/approve/${id}`;
    const denyLink = `${baseUrl}/leaves/deny/${id}`;

    const detailsHtml = `
      <h3>Leave Request</h3>
      <p><strong>Employee:</strong> ${leaveDoc.employeeName} (${leaveDoc.employeeId || 'N/A'})</p>
      <p><strong>Email:</strong> ${leaveDoc.employeeEmail}</p>
      <p><strong>Type:</strong> ${leaveDoc.leaveType}</p>
      <p><strong>Dates:</strong> ${leaveDoc.startDate} to ${leaveDoc.endDate}</p>
      <p><strong>Reason:</strong> ${leaveDoc.reason || ''}</p>
      <p>
        <a href="${approveLink}">Approve</a> |
        <a href="${denyLink}">Deny</a>
      </p>
    `;

    // Send email to admin (and cc employee)
    // NOTE: For emails to be sent, you must configure the environment variables
    // as described in /config/mailer.js. Otherwise, it will default to a 
    // test account and only log a URL to the console.
    try {
      await mailer.sendMail({
        to: ADMIN_EMAIL,
        subject: `New Leave Request from ${leaveDoc.employeeName}`,
        html: detailsHtml,
      });
      // Also send a confirmation to employee
      await mailer.sendMail({
        to: leaveDoc.employeeEmail,
        subject: `Leave Request Received (${leaveDoc.leaveType})`,
        html: `<p>Hi ${leaveDoc.employeeName},</p><p>Your leave request has been received and is pending review.</p>${detailsHtml}`,
      });
    } catch (mailErr) {
      console.error('Error sending notification emails:', mailErr);
      // continue - do not fail the request because of email issues
    }

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

async function updateLeave(req, res) {
  try {
    const { id } = req.params;
    const payload = req.body; // Expecting { status: 'approved' | 'denied' } or full form update

    const record = await redisClient.hGet(LEAVES_KEY, id);
    if (!record) {
      return res.status(404).json({ error: "Leave form not found." });
    }

    const existingLeave = JSON.parse(record);
    const previousStatus = existingLeave.status;

    // If only status is provided, just update that. Otherwise, update the whole form.
    const updatedLeave = {
      ...existingLeave,
      ...payload,
      updatedAt: new Date().toISOString(),
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));

    // If status has changed, send notification email
    if (payload.status && payload.status !== previousStatus) {
      const { status } = payload;
      const subject = `Leave Request ${status.charAt(0).toUpperCase() + status.slice(1)}`;
      const html = `<p>Hi ${updatedLeave.employeeName || 'Employee'},</p>
                 <p>Your leave request for ${updatedLeave.startDate} to ${updatedLeave.endDate} has been <strong>${status.toUpperCase()}</strong>.</p>
                 <p>Request ID: ${updatedLeave.id}</p>`;

      if (updatedLeave.employeeEmail && (status === 'approved' || status === 'denied')) {
        try {
          await mailer.sendMail({
            to: updatedLeave.employeeEmail,
            subject: subject,
            html: html,
          });
        } catch (mailErr) {
          console.error(`Error sending ${status} email:`, mailErr);
        }
      }
    }

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

export default { createLeave, listLeaves, getLeave, updateLeave, deleteLeave };