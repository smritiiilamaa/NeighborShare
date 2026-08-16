const { isValidRole } = require("../src/validators/accountValidator");

// Unit test 1 - story D2 / R2: account role must be Donor or Recipient.
describe("isValidRole", () => {
    test("accepts Donor and Recipient", () => {
        expect(isValidRole("Donor")).toBe(true);
        expect(isValidRole("Recipient")).toBe(true);
    });

    test("rejects an unsupported role", () => {
        expect(isValidRole("Administrator")).toBe(false);
    });

    test("rejects empty and missing values", () => {
        expect(isValidRole("")).toBe(false);
        expect(isValidRole(undefined)).toBe(false);
    });
});
