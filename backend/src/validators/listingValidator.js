// Validation rules for food listings. Pure functions - no database, no req/res.

const allowedCategories = [
    "Cooked Meals",
    "Bakery",
    "Fruits",
    "Vegetables",
    "Other"
];

// Returns true only for categories the system supports.
function isValidCategory(category) {
    return allowedCategories.includes(String(category ?? "").trim());
}

// Returns true when every field required to save a listing is present.
function hasRequiredListingFields(listing = {}) {
    const accountId = Number(listing.account_id);

    return (
        Number.isInteger(accountId) &&
        accountId > 0 &&
        Boolean(String(listing.food_name ?? "").trim()) &&
        Boolean(String(listing.category ?? "").trim()) &&
        Boolean(String(listing.quantity ?? "").trim()) &&
        Boolean(String(listing.pickup_location ?? "").trim())
    );
}

module.exports = { allowedCategories, isValidCategory, hasRequiredListingFields };
