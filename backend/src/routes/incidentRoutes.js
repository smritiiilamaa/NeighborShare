const express = require("express");

const router = express.Router();

const {
    createIncidentReport,
    getAllIncidentReports,
    updateIncidentStatus
} = require("../controllers/incidentController");

router.post("/", createIncidentReport);
router.get("/", getAllIncidentReports);
router.put("/:id/status", updateIncidentStatus);

module.exports = router;
