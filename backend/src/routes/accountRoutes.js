const express = require("express");
const router = express.Router();

const {
    createAccount,
    loginAccount
} = require("../controllers/accountController");

router.post("/", createAccount);
router.post("/login", loginAccount);

module.exports = router;