// Validation rules for user accounts. Pure functions - no database, no req/res.

const allowedRoles = ["Donor", "Recipient"];

// Returns true only for the roles the system supports.
function isValidRole(role) {
    return allowedRoles.includes(String(role ?? "").trim());
}

module.exports = { allowedRoles, isValidRole };
