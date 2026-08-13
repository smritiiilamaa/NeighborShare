const pool = require("../config/db");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");


const allowedDietaryPreferences = [
    "None",
    "Vegetarian",
    "Vegan",
    "Gluten-Free",
    "Dairy-Free",
    "Nut-Free",
    "Halal",
    "Kosher"
];

const createRecipient = async (req, res) => {
    let client;
    let transactionStarted = false;

    try {
        const {
            full_name,
            email,
            phone_number,
            street_address,
            city,
            postal_code,
            dietary_preference,
            allergies
        } = req.body;

        if (
            !full_name?.trim() ||
            !email?.trim() ||
            !phone_number?.trim() ||
            !street_address?.trim() ||
            !city?.trim() ||
            !postal_code?.trim() ||
            !dietary_preference?.trim()
        ) {
            return res.status(400).json({
                message: "All required fields must be provided."
            });
        }

        if (!allowedDietaryPreferences.includes(dietary_preference.trim())) {
            return res.status(400).json({
                message: "Invalid dietary preference."
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        client = await pool.connect();

        await client.query("BEGIN");
        transactionStarted = true;

        // Make sure this email does not already have an account.
        const existingAccount = await client.query(
            `SELECT account_id
             FROM user_accounts
             WHERE email = $1`,
            [normalizedEmail]
        );

        if (existingAccount.rows.length > 0) {
            await client.query("ROLLBACK");
            transactionStarted = false;

            return res.status(409).json({
                message: "An account with this email already exists."
            });
        }

        /*
         * Password/login setup is handled the same way as donor creation:
         * create a temporary random value because password_hash is required.
         */
        const temporaryPassword = crypto.randomBytes(32).toString("hex");
        const passwordHash = await bcrypt.hash(temporaryPassword, 10);

        const accountResult = await client.query(
            `INSERT INTO user_accounts
            (
                email,
                password_hash,
                role
            )
            VALUES ($1, $2, $3)
            RETURNING account_id, email, role, account_status`,
            [
                normalizedEmail,
                passwordHash,
                "Recipient"
            ]
        );

        const account = accountResult.rows[0];

        const recipientResult = await client.query(
            `INSERT INTO recipient_profiles
            (
                account_id,
                full_name,
                email,
                phone_number,
                street_address,
                city,
                postal_code,
                dietary_preference,
                allergies
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *`,
            [
                account.account_id,
                full_name.trim(),
                normalizedEmail,
                phone_number.trim(),
                street_address.trim(),
                city.trim(),
                postal_code.trim().toUpperCase(),
                dietary_preference.trim(),
                allergies?.trim() || null
            ]
        );

        await client.query("COMMIT");
        transactionStarted = false;

        return res.status(201).json({
            message: "Recipient account and profile created successfully.",
            account,
            recipient: recipientResult.rows[0]
        });
    } catch (error) {
        if (client && transactionStarted) {
            await client.query("ROLLBACK");
        }

        console.error("Create recipient error:", error);

        if (error.code === "23505") {
            return res.status(409).json({
                message:
                    "An account or recipient profile with this email already exists."
            });
        }

        return res.status(500).json({
            message: "Error creating recipient account and profile."
        });
    } finally {
        if (client) {
            client.release();
        }
    }
};

const getAllRecipients = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM recipient_profiles
             ORDER BY recipient_id ASC`
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving recipient profiles."
        });
    }
};

const getRecipientById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM recipient_profiles
             WHERE recipient_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving recipient profile."
        });
    }
};

const updateRecipient = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            full_name,
            email,
            phone_number,
            street_address,
            city,
            postal_code,
            dietary_preference,
            allergies
        } = req.body;

        if (
            !full_name?.trim() ||
            !email?.trim() ||
            !phone_number?.trim() ||
            !street_address?.trim() ||
            !city?.trim() ||
            !postal_code?.trim() ||
            !dietary_preference?.trim()
        ) {
            return res.status(400).json({
                message: "All required fields must be provided."
            });
        }

        if (!allowedDietaryPreferences.includes(dietary_preference.trim())) {
            return res.status(400).json({
                message: "Invalid dietary preference."
            });
        }

        const result = await pool.query(
            `UPDATE recipient_profiles
             SET full_name = $1,
                 email = $2,
                 phone_number = $3,
                 street_address = $4,
                 city = $5,
                 postal_code = $6,
                 dietary_preference = $7,
                 allergies = $8
             WHERE recipient_id = $9
             RETURNING *`,
            [
                full_name.trim(),
                email.trim().toLowerCase(),
                phone_number.trim(),
                street_address.trim(),
                city.trim(),
                postal_code.trim().toUpperCase(),
                dietary_preference.trim(),
                allergies?.trim() || null,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        if (error.code === "23505") {
            return res.status(409).json({
                message: "A recipient profile with this email already exists."
            });
        }

        return res.status(500).json({
            message: "Error updating recipient profile."
        });
    }
};

const deleteRecipient = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM recipient_profiles
             WHERE recipient_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        return res.status(200).json({
            message: "Recipient profile deleted successfully.",
            recipient: result.rows[0]
        });
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error deleting recipient profile."
        });
    }
};

module.exports = {
    createRecipient,
    getAllRecipients,
    getRecipientById,
    updateRecipient,
    deleteRecipient
};