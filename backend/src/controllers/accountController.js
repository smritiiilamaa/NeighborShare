const pool = require("../config/db");
const bcrypt = require("bcryptjs");
const {isValidRole} = require("../validators/accountValidator");

const createAccount = async (req, res) => {
    try {
        const { email, password, role } = req.body;

        if (!email?.trim() || !password?.trim() || !role?.trim()) {
            return res.status(400).json({
                message: "Email, password and role are required."
            });
        }

        const normalizedEmail = email.trim().toLowerCase();
        const normalizedRole = role.trim();

        if (!isValidRole(normalizedRole)) {
            return res.status(400).json({
                message: "Role must be Donor or Recipient."
            });
        }

        const existingAccount = await pool.query(
            `SELECT account_id
             FROM user_accounts
             WHERE email = $1`,
            [normalizedEmail]
        );

        if (existingAccount.rows.length > 0) {
            return res.status(409).json({
                message: "An account with this email already exists."
            });
        }

        const passwordHash = await bcrypt.hash(password.trim(), 10);

        const result = await pool.query(
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
                normalizedRole
            ]
        );

        return res.status(201).json({
            message: "Account created successfully.",
            account: result.rows[0]
        });

    } catch (error) {
        console.error(error);

        if (error.code === "23505") {
            return res.status(409).json({
                message: "An account with this email already exists."
            });
        }

        return res.status(500).json({
            message: "Error creating account."
        });
    }
};

const loginAccount = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email?.trim() || !password?.trim()) {
            return res.status(400).json({
                message: "Email and password are required."
            });
        }

        const normalizedEmail = email.trim().toLowerCase();

        const result = await pool.query(
            `SELECT account_id, email, password_hash, role, account_status
             FROM user_accounts
             WHERE email = $1`,
            [normalizedEmail]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({
                message: "Invalid email or password."
            });
        }

        const account = result.rows[0];

        const passwordMatches = await bcrypt.compare(
            password,
            account.password_hash
        );

        if (!passwordMatches) {
            return res.status(401).json({
                message: "Invalid email or password."
            });
        }

        if (account.account_status === "Banned") {
            return res.status(403).json({
                message:
                    "This account has been banned for community guideline violations."
            });
        }

        if (account.role !== "Administrator") {
            return res.status(403).json({
                message:
                    "Access denied. This account does not have administrator permission."
            });
        }

        return res.status(200).json({
            message: "Administrator login successful.",
            account: {
                account_id: account.account_id,
                email: account.email,
                role: account.role
            }
        });

    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error logging in."
        });
    }
};

module.exports = {
    createAccount,
    loginAccount
};