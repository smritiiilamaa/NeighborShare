const express = require("express");
const router = express.Router();

const {
    getMessagesByRecipient,
    getMessagesByDonor,
    getConversation,
    markMessagesAsRead,
    markDonorMessagesAsRead,
    sendMessage
} = require("../controllers/messageController");

router.post("/", sendMessage);
router.get("/conversation", getConversation);
router.get("/donor/:donorId", getMessagesByDonor);
router.patch("/donor/:donorId/read", markDonorMessagesAsRead);
router.patch("/:recipientId/read", markMessagesAsRead);
router.get("/:recipientId", getMessagesByRecipient);

module.exports = router;