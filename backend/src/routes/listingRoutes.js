const express = require("express");

const router = express.Router();

const {
    createListing,
    getAllListings,
    getListingById,
    getListingsByDonor,
    updateListing,
    getAvailableListings,
    deleteListing,
    getFlaggedListings,
    flagListing,
    updateModerationStatus
} = require("../controllers/listingController");

router.post("/", createListing);
router.get("/", getAllListings);
router.get("/flagged", getFlaggedListings);
router.get("/donor/:id", getListingsByDonor);
router.get("/available", getAvailableListings);
router.get("/:id", getListingById);
router.put("/:id", updateListing);
router.put("/:id/flag", flagListing);
router.put("/:id/moderation-status", updateModerationStatus);
router.delete("/:id", deleteListing);

module.exports = router;