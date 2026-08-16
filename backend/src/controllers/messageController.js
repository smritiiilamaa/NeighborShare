const pool = require("../config/db");

// Simple keyword-based profanity filter. Not exhaustive, but blocks the
// clearest cases per story D7/R8's negative test ("message with profanity").
const bannedWords = [
    "damn",
    "hell",
    "shit",
    "fuck",
    "bitch",
    "asshole",
    "bastard"
];

const containsProfanity = (text) => {
    const normalized = text.toLowerCase();
    return bannedWords.some((word) =>
        new RegExp(`\\b${word}\\b`, "i").test(normalized)
    );
};

const allowedSenderRoles = ["Donor", "Recipient"];

const getMessagesByDonor = async (req, res) => {
    try {
        const { donorId } = req.params;
        const parsedDonorId = Number(donorId);

        if (!Number.isInteger(parsedDonorId) || parsedDonorId <= 0) {
            return res.status(400).json({
                message: "A valid donor ID is required."
            });
        }

        const donorResult = await pool.query(
            `SELECT donor_id
             FROM donor_profiles
             WHERE donor_id = $1`,
            [parsedDonorId]
        );

        if (donorResult.rows.length === 0) {
            return res.status(404).json({
                message: "Donor profile not found."
            });
        }

        const result = await pool.query(
            `SELECT
                message_id,
                donor_id,
                recipient_id,
                message,
                sent_at,
                is_read,
                sender_role
             FROM messages
             WHERE donor_id = $1
             ORDER BY sent_at ASC`,
            [parsedDonorId]
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error("Get donor messages error:", error);

        return res.status(500).json({
            message: "Error retrieving donor messages."
        });
    }
};

const getMessagesByRecipient = async (req, res) => {
    try {
        const { recipientId } = req.params;

        const recipientResult = await pool.query(
            `SELECT recipient_id
             FROM recipient_profiles
             WHERE recipient_id = $1`,
            [recipientId]
        );

        if (recipientResult.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        const result = await pool.query(
            `SELECT message_id, donor_id, recipient_id, message, sent_at, is_read, sender_role
             FROM messages
             WHERE recipient_id = $1
             ORDER BY sent_at ASC`,
            [recipientId]
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving messages."
        });
    }
};

const getConversation = async (req, res) => {
    try {
        const { donorId, recipientId } = req.query;
        const parsedDonorId = Number(donorId);
        const parsedRecipientId = Number(recipientId);

        if (
            !Number.isInteger(parsedDonorId) ||
            parsedDonorId <= 0 ||
            !Number.isInteger(parsedRecipientId) ||
            parsedRecipientId <= 0
        ) {
            return res.status(400).json({
                message: "Valid donorId and recipientId query parameters are required."
            });
        }

        const result = await pool.query(
            `SELECT message_id, donor_id, recipient_id, message, sent_at, is_read, sender_role
             FROM messages
             WHERE donor_id = $1 AND recipient_id = $2
             ORDER BY sent_at ASC`,
            [parsedDonorId, parsedRecipientId]
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving conversation."
        });
    }
};

const markMessagesAsRead = async (req, res) => {
    try {
        const { recipientId } = req.params;
        const { message_ids: messageIds } = req.body || {};

        const parsedRecipientId = Number(recipientId);

        if (!Number.isInteger(parsedRecipientId) || parsedRecipientId <= 0) {
            return res.status(400).json({
                message: "A valid recipient ID is required."
            });
        }

        if (!Array.isArray(messageIds) || messageIds.length === 0) {
            return res.status(400).json({
                message: "At least one message ID is required."
            });
        }

        const result = await pool.query(
            `UPDATE messages
             SET is_read = TRUE
             WHERE recipient_id = $1
               AND message_id = ANY($2::int[])
             RETURNING message_id, is_read`,
            [parsedRecipientId, messageIds]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "No messages found for this recipient."
            });
        }

        return res.status(200).json({
            messages: result.rows
        });
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error marking messages as read."
        });
    }
};

const sendMessage = async (req, res) => {
    try {
        const {
            donor_id: donorId,
            recipient_id: recipientId,
            message,
            sender_role: senderRole
        } = req.body || {};
        const parsedDonorId = Number(donorId);
        const parsedRecipientId = Number(recipientId);

        if (!Number.isInteger(parsedDonorId) || parsedDonorId <= 0) {
            return res.status(400).json({
                message: "A valid donor ID is required."
            });
        }

        if (!Number.isInteger(parsedRecipientId) || parsedRecipientId <= 0) {
            return res.status(400).json({
                message: "A valid recipient ID is required."
            });
        }

        if (!allowedSenderRoles.includes(senderRole)) {
            return res.status(400).json({
                message: "A valid sender_role ('Donor' or 'Recipient') is required."
            });
        }

        const trimmedMessage = message?.trim();

        if (!trimmedMessage) {
            return res.status(400).json({
                message: "Message content is required."
            });
        }

        if (containsProfanity(trimmedMessage)) {
            return res.status(400).json({
                message: "Message contains inappropriate language and was not sent."
            });
        }

        const recipientResult = await pool.query(
            `SELECT recipient_id
             FROM recipient_profiles
             WHERE recipient_id = $1`,
            [parsedRecipientId]
        );

        if (recipientResult.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        const donorResult = await pool.query(
            `SELECT donor_id
             FROM donor_profiles
             WHERE donor_id = $1`,
            [parsedDonorId]
        );

        if (donorResult.rows.length === 0) {
            return res.status(404).json({
                message: "Donor profile not found."
            });
        }

        const result = await pool.query(
            `INSERT INTO messages (donor_id, recipient_id, message, sender_role)
             VALUES ($1, $2, $3, $4)
             RETURNING message_id, donor_id, recipient_id, message, sent_at, is_read, sender_role`,
            [parsedDonorId, parsedRecipientId, trimmedMessage, senderRole]
        );

        return res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error sending message."
        });
    }
};

const markDonorMessagesAsRead = async (req, res) => {
    try {
        const { donorId } = req.params;
        const { message_ids: messageIds } = req.body || {};

        const parsedDonorId = Number(donorId);

        if (!Number.isInteger(parsedDonorId) || parsedDonorId <= 0) {
            return res.status(400).json({
                message: "A valid donor ID is required."
            });
        }

        if (!Array.isArray(messageIds) || messageIds.length === 0) {
            return res.status(400).json({
                message: "At least one message ID is required."
            });
        }

        const result = await pool.query(
            `UPDATE messages
             SET is_read = TRUE
             WHERE donor_id = $1
               AND message_id = ANY($2::int[])
             RETURNING message_id, is_read`,
            [parsedDonorId, messageIds]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "No messages found for this donor."
            });
        }

        return res.status(200).json({
            message: "Messages marked as read.",
            messages: result.rows
        });
    } catch (error) {
        console.error("Mark donor messages read error:", error);

        return res.status(500).json({
            message: "Error marking messages as read."
        });
    }
};

module.exports = {
    getMessagesByRecipient,
    getMessagesByDonor,
    getConversation,
    markMessagesAsRead,
    markDonorMessagesAsRead,
    sendMessage
};