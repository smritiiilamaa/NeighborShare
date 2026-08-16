require("dotenv").config();

const app = require("./src/app");
const pool = require("./src/config/db");

const PORT = process.env.PORT || 3000;

app.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT NOW()");
    res.json({
      message: "NeighborShare Backend ACTIVE and buying!",
      databaseTime: result.rows[0].now,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      message: "Database connection failed",
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});