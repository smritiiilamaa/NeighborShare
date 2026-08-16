const {
    isValidCategory,
    hasRequiredListingFields
} = require("../src/validators/listingValidator");

// Unit test 2 - story D4: category must be one of the allowed values.
describe("isValidCategory", () => {
    test("accepts an allowed category", () => {
        expect(isValidCategory("Bakery")).toBe(true);
    });

    test("rejects a category that is not on the list", () => {
        expect(isValidCategory("Frozen")).toBe(false);
    });

    test("ignores surrounding whitespace", () => {
        expect(isValidCategory("  Fruits  ")).toBe(true);
    });
});

// Unit test 3 - story D4 negative test: reject an incomplete listing.
describe("hasRequiredListingFields", () => {
    const validListing = {
        account_id: 1,
        food_name: "Rice",
        category: "Other",
        quantity: "2 kg",
        pickup_location: "Scarborough"
    };

    test("accepts a complete listing", () => {
        expect(hasRequiredListingFields(validListing)).toBe(true);
    });

    test("rejects a listing with a missing food name", () => {
        expect(
            hasRequiredListingFields({ ...validListing, food_name: "   " })
        ).toBe(false);
    });

    test("rejects a listing with an invalid account id", () => {
        expect(
            hasRequiredListingFields({ ...validListing, account_id: 0 })
        ).toBe(false);
    });
});
