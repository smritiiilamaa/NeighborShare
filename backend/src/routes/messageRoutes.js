const express = require("express");
const router = express.Router();

const {
	getMessagesByRecipient,
	getConversation,
	markMessagesAsRead,
	sendMessage
} = require("../controllers/messageController");

router.post("/", sendMessage);
router.get("/conversation", getConversation);
router.patch("/:recipientId/read", markMessagesAsRead);
router.get("/:recipientId", getMessagesByRecipient);

module.exports = router;