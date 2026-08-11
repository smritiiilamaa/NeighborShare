const pool = require("../config/db");

const allowedCategories = [
    "Cooked Meals",
    "Bakery",
    "Fruits",
    "Vegetables",
    "Other"
];

const allowedStatuses = [
    "Available",
    "Reserved",
    "Collected",
    "Expired",
    "Cancelled"
];

const createListing = async (req, res) => {
    try {
        const {
            account_id,
            food_name,
            category,
            quantity,
            pickup_location,
            description
        } = req.body;

        const cleanQuantity = String(quantity ?? "").trim();
        const accountId = Number(account_id);

        if (
            !Number.isInteger(accountId) ||
            accountId <= 0 ||
            !food_name?.trim() ||
            !category?.trim() ||
            !cleanQuantity ||
            !pickup_location?.trim()
        ) {
            return res.status(400).json({
                message:
                    "Account ID and all required listing fields must be provided."
            });
        }

        if (!allowedCategories.includes(category.trim())) {
            return res.status(400).json({
                message: "Invalid food category."
            });
        }

        // Convert account_id into donor_id.
        const donorResult = await pool.query(
            `SELECT donor_id
             FROM donor_profiles
             WHERE account_id = $1`,
            [accountId]
        );

        if (donorResult.rows.length === 0) {
            return res.status(404).json({
                message:
                    "Donor profile not found. Please create a donor profile first."
            });
        }

        const donorId = donorResult.rows[0].donor_id;

        const result = await pool.query(
            `INSERT INTO food_listings
            (
                donor_id,
                food_name,
                category,
                quantity,
                pickup_location,
                description,
                status
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *`,
            [
                donorId,
                food_name.trim(),
                category.trim(),
                cleanQuantity,
                pickup_location.trim(),
                description?.trim() || null,
                "Available"
            ]
        );

        return res.status(201).json({
            message: "Food listing created successfully.",
            listing: result.rows[0]
        });
    } catch (error) {
        console.error("Create listing error:", error);

        return res.status(500).json({
            message: "Error creating food listing."
        });
    }
};

const getAllListings = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                food_listings.*,
                donor_profiles.full_name AS donor_name
             FROM food_listings
             JOIN donor_profiles
                ON food_listings.donor_id = donor_profiles.donor_id
             ORDER BY food_listings.listing_id ASC`
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving food listings."
        });
    }
};

const getListingById = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT
                food_listings.*,
                donor_profiles.full_name AS donor_name
             FROM food_listings
             JOIN donor_profiles
                ON food_listings.donor_id = donor_profiles.donor_id
             WHERE food_listings.listing_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Food listing not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving food listing."
        });
    }
};

const getListingsByDonor = async (req, res) => {
    try {
        const { id: accountId } = req.params;

        // Find the donor profile for this account
        const donorResult = await pool.query(
            `SELECT donor_id
             FROM donor_profiles
             WHERE account_id = $1`,
            [accountId]
        );

        if (donorResult.rows.length === 0) {
            return res.status(404).json({
                message: "Donor profile not found."
            });
        }

        const donorId = donorResult.rows[0].donor_id;

        // Get only this donor's listings
        const result = await pool.query(
            `SELECT *
             FROM food_listings
             WHERE donor_id = $1
             ORDER BY created_at DESC`,
            [donorId]
        );

        return res.status(200).json(result.rows);

    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving donor listings."
        });
    }
};

const getAvailableListings = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                food_listings.*,
                donor_profiles.full_name AS donor_name
             FROM food_listings
             JOIN donor_profiles
                ON food_listings.donor_id = donor_profiles.donor_id
             WHERE food_listings.status = $1
             ORDER BY food_listings.created_at DESC`,
            ["Available"]
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error("Get available listings error:", error);

        return res.status(500).json({
            message: "Error retrieving available food listings."
        });
    }
};

const updateListing = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            food_name,
            category,
            quantity,
            pickup_location,
            description,
            status
        } = req.body;

        const cleanQuantity = String(quantity ?? "").trim();

        if (
            !food_name?.trim() ||
            !category?.trim() ||
            !cleanQuantity ||
            !pickup_location?.trim() ||
            !status?.trim()
        ) {
            return res.status(400).json({
                message: "All required fields must be provided."
            });
        }

        if (!allowedCategories.includes(category.trim())) {
            return res.status(400).json({
                message: "Invalid food category."
            });
        }

        if (!allowedStatuses.includes(status.trim())) {
            return res.status(400).json({
                message: "Invalid listing status."
            });
        }

        const result = await pool.query(
            `UPDATE food_listings
             SET food_name = $1,
                 category = $2,
                 quantity = $3,
                 pickup_location = $4,
                 description = $5,
                 status = $6
             WHERE listing_id = $7
             RETURNING *`,
            [
                food_name.trim(),
                category.trim(),
                cleanQuantity,
                pickup_location.trim(),
                description?.trim() || null,
                status.trim(),
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Food listing not found."
            });
        }

        return res.status(200).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error updating food listing."
        });
    }
};

const deleteListing = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM food_listings
             WHERE listing_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Food listing not found."
            });
        }

        return res.status(200).json({
            message: "Food listing deleted successfully.",
            listing: result.rows[0]
        });
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error deleting food listing."
        });
    }
};

module.exports = {
    createListing,
    getAllListings,
    getListingById,
    getListingsByDonor,
    updateListing,
    getAvailableListings,
    deleteListing
};