const pool = require("../config/db");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");

const isValidEmail = (email) => {
    const emailRegex =
        /^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$/;

    return emailRegex.test(email);
};

const isValidPhone = (phone) => {
    const digitsOnly = phone.replace(/\D/g, "");
    return digitsOnly.length === 10;
};

const isValidCanadianPostalCode = (postalCode) => {
    const postalRegex =
        /^[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTV-Z] ?\d[ABCEGHJ-NPRSTV-Z]\d$/i;

    return postalRegex.test(postalCode);
};

const createDonor = async (req, res) => {
    let client;
    let transactionStarted = false;

    try {
        const {
            full_name,
            email,
            phone_number,
            street_address,
            city,
            postal_code
        } = req.body;

        if (
            !full_name?.trim() ||
            !email?.trim() ||
            !phone_number?.trim() ||
            !street_address?.trim() ||
            !city?.trim() ||
            !postal_code?.trim()
        ) {
            return res.status(400).json({
                message: "All donor profile fields are required."
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        client = await pool.connect();

        await client.query("BEGIN");
        transactionStarted = true;

        // Make sure the email is not already registered.
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
         * Login is not implemented yet, but password_hash is required
         * by the database. Generate and hash a random temporary value.
         */
        const temporaryPassword = crypto.randomBytes(32).toString("hex");
        const passwordHash = await bcrypt.hash(temporaryPassword, 10);

        // PostgreSQL automatically generates account_id.
        const accountResult = await client.query(
            `INSERT INTO user_accounts
            (
                email,
                password_hash,
                role
            )
            VALUES ($1, $2, $3)
            RETURNING account_id, email, role`,
            [
                normalizedEmail,
                passwordHash,
                "Donor"
            ]
        );

        const account = accountResult.rows[0];

        // Use the generated account_id to create the donor profile.
        const donorResult = await client.query(
            `INSERT INTO donor_profiles
            (
                account_id,
                full_name,
                email,
                phone_number,
                street_address,
                city,
                postal_code
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *`,
            [
                account.account_id,
                full_name.trim(),
                normalizedEmail,
                phone_number.trim(),
                street_address.trim(),
                city.trim(),
                postal_code.trim().toUpperCase()
            ]
        );

        await client.query("COMMIT");
        transactionStarted = false;

        return res.status(201).json({
            message: "Donor account and profile created successfully.",
            account,
            donor: donorResult.rows[0]
        });
    } catch (error) {
        if (client && transactionStarted) {
            await client.query("ROLLBACK");
        }

        console.error("Create donor error:", error);

        if (error.code === "23505") {
            return res.status(409).json({
                message:
                    "An account or donor profile with this email already exists."
            });
        }

        return res.status(500).json({
            message: "Error creating donor account and profile."
        });
    } finally {
        if (client) {
            client.release();
        }
    }
};

const getAllDonors = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT *
             FROM donor_profiles
             ORDER BY donor_id ASC`
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving donor profiles."
        });
    }
};

const getDonorById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT *
             FROM donor_profiles
             WHERE donor_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Donor profile not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving donor profile."
        });
    }
};

const updateDonor = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            full_name,
            email,
            phone_number,
            street_address,
            city,
            postal_code
        } = req.body;

        if (
            !full_name?.trim() ||
            !email?.trim() ||
            !phone_number?.trim() ||
            !street_address?.trim() ||
            !city?.trim() ||
            !postal_code?.trim()
        ) {
            return res.status(400).json({
                message: "All fields are required."
            });
        }

        const normalizedEmail =
            email.trim().toLowerCase();

        if (!isValidEmail(normalizedEmail)) {
            return res.status(400).json({
                message: "Enter a valid email address."
            });
        }

        if (!isValidPhone(phone_number.trim())) {
            return res.status(400).json({
                message: "Enter a valid 10-digit phone number."
            });
        }

        if (!isValidCanadianPostalCode(postal_code.trim())) {
            return res.status(400).json({
                message: "Enter a valid Canadian postal code."
            });
        }

        const result = await pool.query(
            `UPDATE donor_profiles
             SET full_name = $1,
                 email = $2,
                 phone_number = $3,
                 street_address = $4,
                 city = $5,
                 postal_code = $6
             WHERE donor_id = $7
             RETURNING *`,
            [
                full_name.trim(),
                normalizedEmail,
                phone_number.trim(),
                street_address.trim(),
                city.trim(),
                postal_code.trim().toUpperCase(),
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Donor profile not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        if (error.code === "23505") {
            return res.status(409).json({
                message: "A donor profile with this email already exists."
            });
        }

        return res.status(500).json({
            message: "Error updating donor profile."
        });
    }
};

const deleteDonor = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM donor_profiles
             WHERE donor_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Donor profile not found."
            });
        }

        return res.status(200).json({
            message: "Donor profile deleted successfully.",
            donor: result.rows[0]
        });
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error deleting donor profile."
        });
    }
};

module.exports = {
    createDonor,
    getAllDonors,
    getDonorById,
    updateDonor,
    deleteDonor
};