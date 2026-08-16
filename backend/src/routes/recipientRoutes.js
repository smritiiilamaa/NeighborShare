const express = require("express");

const router = express.Router();

const {
    createRecipient,
    getAllRecipients,
    getRecipientById,
    updateRecipient,
    deleteRecipient
} = require("../controllers/recipientController");

const {
    getRequestsByRecipient
} = require("../controllers/foodRequestController");

router.post("/", createRecipient);
router.get("/", getAllRecipients);
router.get("/:id/requests", getRequestsByRecipient);
router.get("/:id", getRecipientById);
router.put("/:id", updateRecipient);
router.delete("/:id", deleteRecipient);

module.exports = router;