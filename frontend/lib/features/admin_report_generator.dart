/// Generates a report from raw usage data supplied by the existing data layer.
///
/// This intentionally does NOT fetch from the database/API. In the TAC, data
/// retrieval and report display are owned by other developers. This class only
/// handles assigned report-generation logic so responsibilities do not
/// overlap and merge conflicts are minimized.
class AdminUsageReport {
  final DateTime generatedAt;
  final int donorCount;
  final int recipientCount;
  final int totalListings;
  final int availableListings;
  final int reservedListings;
  final int totalRequests;
  final int pendingRequests;
  final int approvedRequests;

  const AdminUsageReport({
    required this.generatedAt,
    required this.donorCount,
    required this.recipientCount,
    required this.totalListings,
    required this.availableListings,
    required this.reservedListings,
    required this.totalRequests,
    required this.pendingRequests,
    required this.approvedRequests,
  });

  int get totalUsers => donorCount + recipientCount;

  double get approvalRate {
    if (totalRequests == 0) return 0;
    return (approvedRequests / totalRequests) * 100;
  }

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'total_users': totalUsers,
        'donors': donorCount,
        'recipients': recipientCount,
        'total_listings': totalListings,
        'available_listings': availableListings,
        'reserved_listings': reservedListings,
        'total_requests': totalRequests,
        'pending_requests': pendingRequests,
        'approved_requests': approvedRequests,
        'approval_rate_percent': double.parse(approvalRate.toStringAsFixed(1)),
      };
}

class AdminReportGenerator {
  const AdminReportGenerator._();

  static AdminUsageReport generate({
    required List<Map<String, dynamic>> donors,
    required List<Map<String, dynamic>> recipients,
    required List<Map<String, dynamic>> listings,
    required List<Map<String, dynamic>> requests,
    DateTime? generatedAt,
  }) {
    int listingCount(String status) => listings
        .where((item) => _normalized(item['status']) == _normalized(status))
        .length;

    int requestCount(String status) => requests
        .where((item) =>
            _normalized(item['request_status']) == _normalized(status))
        .length;

    return AdminUsageReport(
      generatedAt: generatedAt ?? DateTime.now(),
      donorCount: donors.length,
      recipientCount: recipients.length,
      totalListings: listings.length,
      availableListings: listingCount('Available'),
      reservedListings: listingCount('Reserved'),
      totalRequests: requests.length,
      pendingRequests: requestCount('Pending'),
      approvedRequests: requestCount('Approved'),
    );
  }

  static String _normalized(Object? value) =>
      (value ?? '').toString().trim().toLowerCase();
}
