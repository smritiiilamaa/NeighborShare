const express = require("express");
const cors = require("cors");

const donorRoutes = require("./routes/donorRoutes");
const recipientRoutes = require("./routes/recipientRoutes");
const listingRoutes = require("./routes/listingRoutes");
const foodRequestRoutes = require("./routes/foodRequestRoutes");
const reportRoutes = require("./routes/reportRoutes");
const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/donors", donorRoutes);
app.use("/api/recipients", recipientRoutes);
app.use("/api/listings", listingRoutes);
app.use("/api/requests", foodRequestRoutes);
app.use("/api/reports", reportRoutes);

module.exports = app;