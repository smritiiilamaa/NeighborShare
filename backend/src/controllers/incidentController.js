const pool = require("../config/db");

const allowedStatuses = ["Open", "Investigating", "Resolved"];

const createIncidentReport = async (req, res) => {
    try {
        const { title, description, reported_by } = req.body;

        if (!title?.trim() || !description?.trim()) {
            return res.status(400).json({
                message: "Report title and details are required."
            });
        }

        const result = await pool.query(
            `INSERT INTO incident_reports
            (
                title,
                description,
                reported_by
            )
            VALUES ($1, $2, $3)
            RETURNING *`,
            [
                title.trim(),
                description.trim(),
                reported_by?.trim() || null
            ]
        );

        return res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error creating incident report."
        });
    }
};

const getAllIncidentReports = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM incident_reports
             ORDER BY created_at DESC`
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving incident reports."
        });
    }
};

const updateIncidentStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!status?.trim()) {
            return res.status(400).json({
                message: "Status is required."
            });
        }

        const cleanStatus = status.trim();

        if (!allowedStatuses.includes(cleanStatus)) {
            return res.status(400).json({
                message: "Invalid incident status."
            });
        }

        const result = await pool.query(
            `UPDATE incident_reports
             SET status = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE incident_id = $2
             RETURNING *`,
            [cleanStatus, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Incident report not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error updating incident report status."
        });
    }
};

module.exports = {
    createIncidentReport,
    getAllIncidentReports,
    updateIncidentStatus
};
