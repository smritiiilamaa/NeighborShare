const express = require("express");
const cors = require("cors");

const accountRoutes = require("./routes/accountRoutes");
const donorRoutes = require("./routes/donorRoutes");
const adminRoutes = require("./routes/adminRoutes");
const recipientRoutes = require("./routes/recipientRoutes");
const listingRoutes = require("./routes/listingRoutes");
const foodRequestRoutes = require("./routes/foodRequestRoutes");
const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/donors", donorRoutes);
app.use("/api/recipients", recipientRoutes);
app.use("/api/listings", listingRoutes);
app.use("/api/requests", foodRequestRoutes);
app.use("/api/accounts", accountRoutes);
app.use("/api/admin", adminRoutes);

module.exports = app;