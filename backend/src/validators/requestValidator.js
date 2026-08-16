// Validation and status rules for food requests. Pure functions.

const allowedRequestStatuses = [
    "Pending",
    "Approved",
    "Rejected",
    "Cancelled",
    "Completed"
];

// Returns true only for request statuses the system supports.
function isValidRequestStatus(status) {
    return allowedRequestStatuses.includes(String(status ?? "").trim());
}

// Business rule: a change to a request status drives the listing status.
// Approved reserves the listing, Completed marks it collected, and a
// rejection or cancellation releases it back to other recipients.
// Returns null when the request status does not move the listing.
function mapRequestStatusToListingStatus(requestStatus) {
    const status = String(requestStatus ?? "").trim();

    if (status === "Approved") return "Reserved";
    if (status === "Completed") return "Collected";
    if (status === "Rejected" || status === "Cancelled") return "Available";

    return null;
}

module.exports = {
    allowedRequestStatuses,
    isValidRequestStatus,
    mapRequestStatusToListingStatus
};
