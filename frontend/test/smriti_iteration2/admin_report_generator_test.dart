import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/smriti_iteration2/admin_report_generator.dart';

void main() {
  test('generates correct usage and traffic totals', () {
    final report = AdminReportGenerator.generate(
      donors: [
        {'donor_id': 1},
        {'donor_id': 2},
      ],
      recipients: [
        {'recipient_id': 1},
      ],
      listings: [
        {'status': 'Available'},
        {'status': 'Reserved'},
        {'status': 'Available'},
      ],
      requests: [
        {'request_status': 'Pending'},
        {'request_status': 'Approved'},
      ],
      generatedAt: DateTime(2026, 8, 1),
    );

    expect(report.totalUsers, 3);
    expect(report.totalListings, 3);
    expect(report.availableListings, 2);
    expect(report.reservedListings, 1);
    expect(report.totalRequests, 2);
    expect(report.approvedRequests, 1);
    expect(report.approvalRate, 50);
  });
}
