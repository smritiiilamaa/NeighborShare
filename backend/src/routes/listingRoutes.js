const express = require("express");

const router = express.Router();

const {
    createListing,
    getAllListings,
    getListingById,
    getListingsByDonor,
    updateListing,
    getAvailableListings,
    deleteListing
} = require("../controllers/listingController");

router.post("/", createListing);
router.get("/", getAllListings);
router.get("/donor/:id", getListingsByDonor);
router.get("/available", getAvailableListings);
router.get("/:id", getListingById);
router.put("/:id", updateListing);
router.delete("/:id", deleteListing);

module.exports = router;