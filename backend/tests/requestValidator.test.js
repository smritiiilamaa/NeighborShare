const {
    isValidRequestStatus,
    mapRequestStatusToListingStatus
} = require("../src/validators/requestValidator");

// Unit test 4 - story D9: only supported request statuses are accepted.
describe("isValidRequestStatus", () => {
    test("accepts an allowed status", () => {
        expect(isValidRequestStatus("Approved")).toBe(true);
    });

    test("rejects an unsupported status", () => {
        expect(isValidRequestStatus("Maybe")).toBe(false);
    });
});

// Unit test 5 - story D9 / R9: approving a request reserves the listing so
// no other recipient can claim it.
describe("mapRequestStatusToListingStatus", () => {
    test("Approved reserves the listing", () => {
        expect(mapRequestStatusToListingStatus("Approved")).toBe("Reserved");
    });

    test("Completed marks the listing collected", () => {
        expect(mapRequestStatusToListingStatus("Completed")).toBe("Collected");
    });

    test("Rejected and Cancelled release the listing", () => {
        expect(mapRequestStatusToListingStatus("Rejected")).toBe("Available");
        expect(mapRequestStatusToListingStatus("Cancelled")).toBe("Available");
    });

    test("Pending does not change the listing", () => {
        expect(mapRequestStatusToListingStatus("Pending")).toBeNull();
    });
});
