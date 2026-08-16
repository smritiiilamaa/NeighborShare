const express = require("express");

const router = express.Router();

const {
    createDonor,
    getAllDonors,
    getDonorById,
    updateDonor,
    deleteDonor
} = require("../controllers/donorController");

const {
    getListingsByDonor
} = require("../controllers/listingController");

router.post("/", createDonor);
router.get("/", getAllDonors);
router.get("/:id/listings", getListingsByDonor);
router.get("/:id", getDonorById);
router.put("/:id", updateDonor);
router.delete("/:id", deleteDonor);

module.exports = router;