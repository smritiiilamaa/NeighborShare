const pool = require("../config/db");

const getReportSummary = async (req, res) => {
  try {
    const [
      donorResult,
      recipientResult,
      listingResult,
      requestResult,
      pendingResult,
      acceptedResult,
    ] = await Promise.all([
      pool.query("SELECT COUNT(*) AS count FROM donor_profiles"),
      pool.query("SELECT COUNT(*) AS count FROM recipient_profiles"),
      pool.query("SELECT COUNT(*) AS count FROM listings"),
      pool.query("SELECT COUNT(*) AS count FROM food_requests"),
      pool.query(
        "SELECT COUNT(*) AS count FROM food_requests WHERE status = 'Pending'"
      ),
      pool.query(
        "SELECT COUNT(*) AS count FROM food_requests WHERE status = 'Accepted'"
      ),
    ]);

    return res.status(200).json({
      totalDonors: Number(donorResult.rows[0].count),
      totalRecipients: Number(recipientResult.rows[0].count),
      totalListings: Number(listingResult.rows[0].count),
      totalRequests: Number(requestResult.rows[0].count),
      pendingRequests: Number(pendingResult.rows[0].count),
      acceptedRequests: Number(acceptedResult.rows[0].count),
    });
  } catch (error) {
    console.error("Error retrieving report summary:", error);

    return res.status(500).json({
      message: "Unable to retrieve report summary.",
    });
  }
};

module.exports = {
  getReportSummary,
};