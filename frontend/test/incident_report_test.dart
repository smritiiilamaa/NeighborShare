import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/screens/incident_report.dart';

void main() {
  http.Client emptyListClient() {
    return MockClient((request) async {
      return http.Response(jsonEncode([]), 200,
          headers: {'content-type': 'application/json'});
    });
  }

  Future<void> pumpReportPage(
    WidgetTester tester, {
    http.BaseClient? httpClient,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncidentReportPage(httpClient: httpClient ?? emptyListClient()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('displays required incident report fields and action',
      (WidgetTester tester) async {
    await pumpReportPage(tester);

    expect(find.text('Report title'), findsOneWidget);
    expect(find.text('Incident details'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);
  });

  testWidgets('blocks an empty report and displays validation messages',
      (WidgetTester tester) async {
    await pumpReportPage(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pump();

    expect(find.text('Report title is required.'), findsOneWidget);
    expect(find.text('Report details are required.'), findsOneWidget);
  });

  testWidgets('blocks whitespace-only report fields',
      (WidgetTester tester) async {
    await pumpReportPage(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '   ');
    await tester.enterText(fields.at(1), '\n  ');
    await tester.tap(find.text('Submit Report'));
    await tester.pump();

    expect(find.text('Report title is required.'), findsOneWidget);
    expect(find.text('Report details are required.'), findsOneWidget);
  });

  testWidgets('submits a valid report and refreshes the incident list',
      (WidgetTester tester) async {
    var postCalled = false;

    final client = MockClient((request) async {
      if (request.method == 'POST') {
        postCalled = true;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['title'], 'Unsafe food listing');
        expect(body['description'], 'The listing contains expired food.');
        return http.Response(
          jsonEncode({
            'incident_id': 1,
            'title': body['title'],
            'description': body['description'],
            'reported_by': 'Administrator',
            'status': 'Open',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(jsonEncode([]), 200,
          headers: {'content-type': 'application/json'});
    });

    await pumpReportPage(tester, httpClient: client);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Unsafe food listing');
    await tester.enterText(fields.at(1), 'The listing contains expired food.');
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();

    expect(postCalled, isTrue);
    expect(find.text('Incident report submitted.'), findsOneWidget);
    expect(find.text('Report title is required.'), findsNothing);
  });

  testWidgets('displays incident reports fetched from the backend',
      (WidgetTester tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'incident_id': 3,
            'title': 'Inappropriate Food Listing',
            'description': 'Expired food was listed.',
            'reported_by': 'Sarah Johnson',
            'status': 'Open',
            'created_at': '2026-07-26T00:00:00.000Z',
          }
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await pumpReportPage(tester, httpClient: client);

    expect(find.text('INC-003'), findsOneWidget);
    expect(find.text('Inappropriate Food Listing'), findsOneWidget);
    expect(find.text('Reported By: Sarah Johnson'), findsOneWidget);
  });

  testWidgets('Review and Resolve buttons update incident status',
      (WidgetTester tester) async {
    String? lastStatusSent;

    final client = MockClient((request) async {
      if (request.method == 'PUT') {
        lastStatusSent =
            (jsonDecode(request.body) as Map<String, dynamic>)['status'];
        return http.Response(
          jsonEncode({'incident_id': 3, 'status': lastStatusSent}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response(
        jsonEncode([
          {
            'incident_id': 3,
            'title': 'Harassment Complaint',
            'description': 'Reported.',
            'reported_by': 'Emily Davis',
            'status': 'Open',
            'created_at': '2026-07-22T00:00:00.000Z',
          }
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    await pumpReportPage(tester, httpClient: client);

    await tester.ensureVisible(find.text('Review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(lastStatusSent, 'Investigating');
  });
}
