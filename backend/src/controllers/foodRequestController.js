const pool = require("../config/db");
const {isValidRequestStatus,
    mapRequestStatusToListingStatus} = require("../validators/foodRequestValidator");


const createFoodRequest = async (req, res) => {
    try {
        const {
            listing_id,
            recipient_id,
            message
        } = req.body;

        if (!listing_id || !recipient_id) {
            return res.status(400).json({
                message: "Listing ID and recipient ID are required."
            });
        }

        const recipientResult = await pool.query(
            `SELECT recipient_id
             FROM recipient_profiles
             WHERE recipient_id = $1`,
            [recipient_id]
        );

        if (recipientResult.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        const listingResult = await pool.query(
            `SELECT listing_id, status
             FROM food_listings
             WHERE listing_id = $1`,
            [listing_id]
        );

        if (listingResult.rows.length === 0) {
            return res.status(404).json({
                message: "Food listing not found."
            });
        }

        const listingStatus = listingResult.rows[0].status;

        if (listingStatus === "Reserved" || listingStatus === "Collected") {
            return res.status(409).json({
                message: "This food listing has already been claimed."
            });
        }

        if (listingStatus !== "Available") {
            return res.status(409).json({
                message: "This food listing is no longer available."
            });
        }

        const existingRequestResult = await pool.query(
            `SELECT request_id
            FROM food_requests
            WHERE listing_id = $1
                AND recipient_id = $2`,
            [listing_id, recipient_id]
        );

        if (existingRequestResult.rows.length > 0) {
            return res.status(409).json({
                message: "You have already requested this food listing."
            });
        }

        const result = await pool.query(
            `INSERT INTO food_requests
            (
                listing_id,
                recipient_id,
                message
            )
            VALUES ($1, $2, $3)
            RETURNING *`,
            [
                listing_id,
                recipient_id,
                message?.trim() || null
            ]
        );

        return res.status(201).json(result.rows[0]);
    } catch (error) {
        console.error(error);

        if (error.code === "23505") {
            return res.status(409).json({
                message: "This recipient has already requested this listing."
            });
        }

        return res.status(500).json({
            message: "Error creating food request."
        });
    }
};

const getAllFoodRequests = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                food_requests.*,
                food_listings.food_name,
                recipient_profiles.full_name AS recipient_name
             FROM food_requests
             JOIN food_listings
                ON food_requests.listing_id = food_listings.listing_id
             JOIN recipient_profiles
                ON food_requests.recipient_id = recipient_profiles.recipient_id
             ORDER BY food_requests.request_id ASC`
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving food requests."
        });
    }
};

const getFoodRequestById = async (req, res) => {
    try {
        const { id } = req.params;
        const { recipient_id: recipientId } = req.query || {};

        const parsedRecipientId = Number(recipientId);

        if (!Number.isInteger(parsedRecipientId) || parsedRecipientId <= 0) {
            return res.status(400).json({
                message: "A valid recipient ID is required to verify request ownership."
            });
        }

        const result = await pool.query(
            `SELECT
                food_requests.*,
                food_listings.food_name,
                recipient_profiles.full_name AS recipient_name
             FROM food_requests
             JOIN food_listings
                ON food_requests.listing_id = food_listings.listing_id
             JOIN recipient_profiles
                ON food_requests.recipient_id = recipient_profiles.recipient_id
             WHERE food_requests.request_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Food request not found."
            });
        }

        const request = result.rows[0];

        if (String(request.recipient_id) !== String(parsedRecipientId)) {
            return res.status(403).json({
                message: "Request does not belong to this recipient."
            });
        }

        return res.status(200).json(request);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving food request."
        });
    }
};

const getRequestsByRecipient = async (req, res) => {
    try {
        const { id } = req.params;

        const recipientResult = await pool.query(
            `SELECT recipient_id
             FROM recipient_profiles
             WHERE recipient_id = $1`,
            [id]
        );

        if (recipientResult.rows.length === 0) {
            return res.status(404).json({
                message: "Recipient profile not found."
            });
        }

        const result = await pool.query(
            `SELECT
                food_requests.*,
                food_listings.food_name
             FROM food_requests
             JOIN food_listings
                ON food_requests.listing_id = food_listings.listing_id
             WHERE food_requests.recipient_id = $1
             ORDER BY food_requests.request_id ASC`,
            [id]
        );

        return res.status(200).json(result.rows);
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error retrieving recipient food requests."
        });
    }
};

const updateFoodRequestStatus = async (req, res) => {
    const client = await pool.connect();

    try {
        const { id } = req.params;
        const { request_status } = req.body;

        if (!request_status?.trim()) {
            return res.status(400).json({
                message: "Request status is required."
            });
        }

        const cleanedStatus = request_status.trim();

        if (!isValidRequestStatus(cleanedStatus)) {
            return res.status(400).json({
                message: "Invalid request status."
            });
        }

        await client.query("BEGIN");

        const existingRequestResult = await client.query(
            `SELECT request_id, listing_id, request_status
            FROM food_requests
            WHERE request_id = $1
            FOR UPDATE`,
            [id]
        );

        if (existingRequestResult.rows.length === 0) {
            await client.query("ROLLBACK");

            return res.status(404).json({
                message: "Food request not found."
            });
        }

        const existingRequest = existingRequestResult.rows[0];

        if (
            cleanedStatus === "Approved" &&
            existingRequest.request_status !== "Pending"
        ) {
            await client.query("ROLLBACK");

            return res.status(409).json({
                message: "This request has already been processed and cannot be approved again."
            });
        }

        const requestResult = await client.query(
            `UPDATE food_requests
             SET request_status = $1,
                 updated_at = CURRENT_TIMESTAMP
             WHERE request_id = $2
             RETURNING *`,
            [cleanedStatus, id]
        );

        if (requestResult.rows.length === 0) {
            await client.query("ROLLBACK");

            return res.status(404).json({
                message: "Food request not found."
            });
        }

        const request = requestResult.rows[0];

        const listingStatus = mapRequestStatusToListingStatus(cleanedStatus);

        if (listingStatus) {
            await client.query(
                `UPDATE food_listings
                 SET status = $1
                 WHERE listing_id = $2`,
                [listingStatus, request.listing_id]
            );
        }

        await client.query("COMMIT");

        return res.status(200).json({
            message: "Food request status updated successfully.",
            request
        });
    } catch (error) {
        await client.query("ROLLBACK");
        console.error(error);

        return res.status(500).json({
            message: "Error updating food request status."
        });
    } finally {
        client.release();
    }
};

const deleteFoodRequest = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `DELETE FROM food_requests
             WHERE request_id = $1
             RETURNING *`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                message: "Food request not found."
            });
        }

        return res.status(200).json({
            message: "Food request deleted successfully.",
            request: result.rows[0]
        });
    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Error deleting food request."
        });
    }
};
const getRequestsByDonor = async (req, res) => {
    try {
        const { accountId } = req.params;

        // Get donor_id from account_id
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

        // Get all requests for this donor's listings
        const result = await pool.query(
            `SELECT
                fr.request_id,
                fr.listing_id,
                fr.message,
                fr.request_status,
                fr.requested_at,

                fl.food_name,
                fl.quantity,
                fl.pickup_location,

                rp.recipient_id,
                rp.full_name AS recipient_name,
                rp.phone_number

             FROM food_requests fr

             JOIN food_listings fl
               ON fr.listing_id = fl.listing_id

             JOIN recipient_profiles rp
               ON fr.recipient_id = rp.recipient_id

             WHERE fl.donor_id = $1

             ORDER BY fr.requested_at DESC`,
            [donorId]
        );

        res.status(200).json(result.rows);

    } catch (err) {
        console.error(err);

        res.status(500).json({
            message: "Error retrieving donor requests."
        });
    }
};

module.exports = {
    createFoodRequest,
    getAllFoodRequests,
    getFoodRequestById,
    getRequestsByRecipient,
    getRequestsByDonor,
    updateFoodRequestStatus,
    deleteFoodRequest
};