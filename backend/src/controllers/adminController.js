const pool = require("../config/db");

const banUser = async (req, res) => {
    try {
        const { id } = req.params;

        const accountId = Number(id);

        if (!Number.isInteger(accountId) || accountId <= 0) {
            return res.status(400).json({
                message: "A valid account ID is required."
            });
        }

        const result = await pool.query(
            `UPDATE user_accounts
             SET account_status = $1
             WHERE account_id = $2
             RETURNING account_id, email, role, account_status`,
            ["Banned", accountId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "User account not found."
            });
        }

        return res.status(200).json({
            message: "User account banned successfully.",
            account: result.rows[0]
        });
    } catch (error) {
        console.error("Ban user error:", error);

        return res.status(500).json({
            message: "Error banning user account."
        });
    }
};

module.exports = {
    banUser
};