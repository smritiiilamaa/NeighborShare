const express = require("express");

const router = express.Router();

const {
    banUser
} = require("../controllers/adminController");

router.put("/users/:id/ban", banUser);

module.exports = router;