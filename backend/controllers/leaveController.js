import { v4 as uuidv4 } from "uuid";
import redisClient from "../config/redisClient.js";
import mailer from "../config/mailer.js";

const LEAVES_KEY = "leaves";

// Admin email - this will receive notifications when employees apply for leave
const ADMIN_EMAIL = "sandakamanoj355@gmail.com";

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

    // Prepare action links - use request host for admin to approve/deny from email
    const baseUrl = req.protocol + '://' + req.get('host');
    const approveLink = `${baseUrl}/leaves/approve/${id}`;
    const denyLink = `${baseUrl}/leaves/deny/${id}`;

    const employeeName = leaveDoc.employeeName;
    const leaveType = leaveDoc.leaveType;
    const startDate = leaveDoc.startDate;
    const endDate = leaveDoc.endDate;
    const reason = leaveDoc.reason || "Not specified";

    // Email to Employee - Leave Application Confirmation
    try {
      await mailer.sendMail({
        to: leaveDoc.employeeEmail,
        subject: `Leave Application Submitted - ${leaveType}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">Leave Application Submitted</h2>
            <p>Dear ${employeeName},</p>
            <p>Your leave application has been submitted successfully and is pending approval.</p>
            <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Leave Details:</h3>
              <p><strong>Leave Type:</strong> ${leaveType}</p>
              <p><strong>Start Date:</strong> ${startDate}</p>
              <p><strong>End Date:</strong> ${endDate}</p>
              <p><strong>Reason:</strong> ${reason}</p>
              <p><strong>Status:</strong> <span style="color: orange; font-weight: bold;">PENDING</span></p>
            </div>
            <p>You will be notified once the admin reviews your application.</p>
            <p>Thank you.</p>
          </div>
        `,
      });

      // Email to Admin - New Leave Request with Approve/Deny Links
      await mailer.sendMail({
        to: ADMIN_EMAIL,
        subject: `New Leave Request from ${employeeName} - ${leaveType}`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">New Leave Request Received</h2>
            <p>A new leave request has been submitted and requires your attention.</p>
            <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Employee Details:</h3>
              <p><strong>Name:</strong> ${employeeName}</p>
              <p><strong>Email:</strong> ${leaveDoc.employeeEmail}</p>
              <p><strong>Employee ID:</strong> ${leaveDoc.employeeId || "N/A"}</p>
            </div>
            <div style="background-color: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0;">
              <h3 style="margin-top: 0;">Leave Details:</h3>
              <p><strong>Leave Type:</strong> ${leaveType}</p>
              <p><strong>Start Date:</strong> ${startDate}</p>
              <p><strong>End Date:</strong> ${endDate}</p>
              <p><strong>Reason:</strong> ${reason}</p>
            </div>
            <div style="margin: 30px 0; text-align: center;">
              <a href="${approveLink}" style="background-color: #28a745; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin-right: 15px; font-weight: bold;">✅ APPROVE</a>
              <a href="${denyLink}" style="background-color: #dc3545; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;">❌ DENY</a>
            </div>
            <p style="color: #666; font-size: 12px;">Click the buttons above to approve or deny this request directly from your email.</p>
          </div>
        `,
      });
    } catch (mailErr) {
      console.error('Error sending notification emails:', mailErr);
      // continue - do not fail the request because of email issues
    }

    res.status(201).json({ id, createdAt: timestamp });
  } catch (error) {
    console.error("Leave creation error:", error);
    res.status(500).json({ error: "Leave creation failed." });
  }
}

async function listLeaves(req, res) {
  try {
    const leaves = await redisClient.hGetAll(LEAVES_KEY);
    const result = Object.values(leaves)
      .map((l) => JSON.parse(l))
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    res.json(result);
  } catch (err) {
    console.error("Error listing leaves:", err);
    res.status(500).json({ error: "Failed to list leaves." });
  }
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
    const payload = req.body;

    const leaveString = await redisClient.hGet(LEAVES_KEY, id);
    if (!leaveString) {
      return res.status(404).json({ error: "Leave not found." });
    }

    const existingLeave = JSON.parse(leaveString);
    const previousStatus = existingLeave.status;

    const updatedLeave = {
      ...existingLeave,
      ...payload,
      updatedAt: new Date().toISOString(),
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));

    // If status has changed, send notification email to employee
    if (payload.status && payload.status !== previousStatus) {
      const newStatus = payload.status;

      if (updatedLeave.employeeEmail && (newStatus === 'approved' || newStatus === 'denied')) {
        const isApproved = newStatus === 'approved';
        const statusColor = isApproved ? '#28a745' : '#dc3545';
        const statusText = isApproved ? 'APPROVED' : 'DENIED';
        const emoji = isApproved ? '✅' : '❌';

        try {
          // Send decision notification to employee
          await mailer.sendMail({
            to: updatedLeave.employeeEmail,
            subject: `${emoji} Leave Request ${statusText} - ${updatedLeave.leaveType}`,
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: ${statusColor};">${emoji} Leave Request ${statusText}</h2>
                <p>Dear ${updatedLeave.employeeName || 'Employee'},</p>
                <p>Your leave request has been <strong style="color: ${statusColor};">${statusText}</strong> by the admin.</p>
                <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <h3 style="margin-top: 0;">Leave Details:</h3>
                  <p><strong>Leave Type:</strong> ${updatedLeave.leaveType}</p>
                  <p><strong>Start Date:</strong> ${updatedLeave.startDate}</p>
                  <p><strong>End Date:</strong> ${updatedLeave.endDate}</p>
                  <p><strong>Status:</strong> <span style="color: ${statusColor}; font-weight: bold;">${statusText}</span></p>
                </div>
                ${isApproved 
                  ? '<p>Enjoy your leave! Please ensure all your tasks are handed over appropriately.</p>' 
                  : '<p>If you have any questions regarding this decision, please contact the admin.</p>'
                }
                <p>Thank you.</p>
              </div>
            `,
          });
        } catch (mailErr) {
          console.error(`Error sending ${newStatus} email:`, mailErr);
        }
      }
    }

    res.status(200).json({ id, updatedAt: updatedLeave.updatedAt, status: updatedLeave.status });
  } catch (error) {
    console.error("Leave update error:", error);
    res.status(500).json({ error: "Failed to update leave." });
  }
}

// Approve leave via email link (GET request)
async function approveLeave(req, res) {
  try {
    const { id } = req.params;

    const leaveString = await redisClient.hGet(LEAVES_KEY, id);
    if (!leaveString) {
      return res.status(404).send('<h1>Leave request not found.</h1>');
    }

    const existingLeave = JSON.parse(leaveString);
    
    // Check if already processed
    if (existingLeave.status !== 'pending') {
      return res.send(`
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; text-align: center;">
          <h2>⚠️ Already Processed</h2>
          <p>This leave request has already been <strong>${existingLeave.status.toUpperCase()}</strong>.</p>
        </div>
      `);
    }

    const updatedLeave = {
      ...existingLeave,
      status: 'approved',
      updatedAt: new Date().toISOString(),
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));

    // Send approval notification to employee
    if (updatedLeave.employeeEmail) {
      try {
        await mailer.sendMail({
          to: updatedLeave.employeeEmail,
          subject: `✅ Leave Request APPROVED - ${updatedLeave.leaveType}`,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #28a745;">✅ Leave Request APPROVED</h2>
              <p>Dear ${updatedLeave.employeeName || 'Employee'},</p>
              <p>Your leave request has been <strong style="color: #28a745;">APPROVED</strong> by the admin.</p>
              <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <h3 style="margin-top: 0;">Leave Details:</h3>
                <p><strong>Leave Type:</strong> ${updatedLeave.leaveType}</p>
                <p><strong>Start Date:</strong> ${updatedLeave.startDate}</p>
                <p><strong>End Date:</strong> ${updatedLeave.endDate}</p>
                <p><strong>Status:</strong> <span style="color: #28a745; font-weight: bold;">APPROVED</span></p>
              </div>
              <p>Enjoy your leave! Please ensure all your tasks are handed over appropriately.</p>
              <p>Thank you.</p>
            </div>
          `,
        });
      } catch (mailErr) {
        console.error('Error sending approval email:', mailErr);
      }
    }

    // Return success page to admin
    res.send(`
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; text-align: center;">
        <h2 style="color: #28a745;">✅ Leave Approved Successfully</h2>
        <p>The leave request from <strong>${updatedLeave.employeeName}</strong> has been approved.</p>
        <p>An email notification has been sent to the employee.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Employee:</strong> ${updatedLeave.employeeName}</p>
          <p><strong>Leave Type:</strong> ${updatedLeave.leaveType}</p>
          <p><strong>Dates:</strong> ${updatedLeave.startDate} to ${updatedLeave.endDate}</p>
        </div>
      </div>
    `);
  } catch (error) {
    console.error("Approve leave error:", error);
    res.status(500).send('<h1>Failed to approve leave.</h1>');
  }
}

// Deny leave via email link (GET request)
async function denyLeave(req, res) {
  try {
    const { id } = req.params;

    const leaveString = await redisClient.hGet(LEAVES_KEY, id);
    if (!leaveString) {
      return res.status(404).send('<h1>Leave request not found.</h1>');
    }

    const existingLeave = JSON.parse(leaveString);
    
    // Check if already processed
    if (existingLeave.status !== 'pending') {
      return res.send(`
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; text-align: center;">
          <h2>⚠️ Already Processed</h2>
          <p>This leave request has already been <strong>${existingLeave.status.toUpperCase()}</strong>.</p>
        </div>
      `);
    }

    const updatedLeave = {
      ...existingLeave,
      status: 'denied',
      updatedAt: new Date().toISOString(),
    };

    await redisClient.hSet(LEAVES_KEY, id, JSON.stringify(updatedLeave));

    // Send denial notification to employee
    if (updatedLeave.employeeEmail) {
      try {
        await mailer.sendMail({
          to: updatedLeave.employeeEmail,
          subject: `❌ Leave Request DENIED - ${updatedLeave.leaveType}`,
          html: `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
              <h2 style="color: #dc3545;">❌ Leave Request DENIED</h2>
              <p>Dear ${updatedLeave.employeeName || 'Employee'},</p>
              <p>Your leave request has been <strong style="color: #dc3545;">DENIED</strong> by the admin.</p>
              <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
                <h3 style="margin-top: 0;">Leave Details:</h3>
                <p><strong>Leave Type:</strong> ${updatedLeave.leaveType}</p>
                <p><strong>Start Date:</strong> ${updatedLeave.startDate}</p>
                <p><strong>End Date:</strong> ${updatedLeave.endDate}</p>
                <p><strong>Status:</strong> <span style="color: #dc3545; font-weight: bold;">DENIED</span></p>
              </div>
              <p>If you have any questions regarding this decision, please contact the admin.</p>
              <p>Thank you.</p>
            </div>
          `,
        });
      } catch (mailErr) {
        console.error('Error sending denial email:', mailErr);
      }
    }

    // Return success page to admin
    res.send(`
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; text-align: center;">
        <h2 style="color: #dc3545;">❌ Leave Denied</h2>
        <p>The leave request from <strong>${updatedLeave.employeeName}</strong> has been denied.</p>
        <p>An email notification has been sent to the employee.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Employee:</strong> ${updatedLeave.employeeName}</p>
          <p><strong>Leave Type:</strong> ${updatedLeave.leaveType}</p>
          <p><strong>Dates:</strong> ${updatedLeave.startDate} to ${updatedLeave.endDate}</p>
        </div>
      </div>
    `);
  } catch (error) {
    console.error("Deny leave error:", error);
    res.status(500).send('<h1>Failed to deny leave.</h1>');
  }
}

async function deleteLeave(req, res) {
  try {
    const { id } = req.params;
    await redisClient.hDel(LEAVES_KEY, id);
    res.status(200).json({ message: "Leave form deleted successfully." });
  } catch (error) {
    console.error("Error deleting leave:", error);
    res.status(500).json({ error: "Failed to delete leave." });
  }
}

export default { createLeave, listLeaves, getLeave, updateLeave, deleteLeave, approveLeave, denyLeave };
