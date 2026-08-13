import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:frontend/screens/message_compose.dart';

void main() {
  Widget buildCompose({
    ValueChanged<String>? onSend,
    int? donorId,
    http.BaseClient? httpClient,
  }) {
    return MaterialApp(
      home: MessageComposeScreen(
        donorName: 'Sarah Lee',
        listingName: 'Vegetable Soup',
        onSend: onSend,
        donorId: donorId,
        httpClient: httpClient,
      ),
    );
  }

  testWidgets('displays selected donor and listing information',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildCompose());

    expect(find.text('Sarah Lee'), findsOneWidget);
    expect(find.text('Regarding: Vegetable Soup'), findsOneWidget);
  });

  testWidgets('provides a message input and send button',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildCompose());

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send Message'), findsOneWidget);
  });

  testWidgets('blocks empty and whitespace-only messages',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildCompose());

    await tester.tap(find.text('Send Message'));
    await tester.pump();
    expect(find.text('Enter a message before sending.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Send Message'));
    await tester.pump();
    expect(find.text('Enter a message before sending.'), findsOneWidget);
  });

  testWidgets('invokes the local callback before attempting to send',
      (WidgetTester tester) async {
    String? submittedMessage;
    await tester.pumpWidget(
      buildCompose(onSend: (message) => submittedMessage = message),
    );

    await tester.enterText(find.byType(TextField), ' Is the soup available? ');
    await tester.tap(find.text('Send Message'));
    await tester.pump();

    expect(submittedMessage, 'Is the soup available?');
  });

  testWidgets('shows an error when no donor is available to message',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildCompose());

    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.tap(find.text('Send Message'));
    await tester.pump();

    expect(
      find.text('This listing is missing a donor to message.'),
      findsOneWidget,
    );
  });

  testWidgets('sends a real message and navigates to the chat thread',
      (WidgetTester tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'message_id': 1,
          'donor_id': 4,
          'recipient_id': 1,
          'message': 'Hello there',
          'sent_at': '2026-01-01T10:00:00.000Z',
          'is_read': false,
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(buildCompose(donorId: 4, httpClient: client));

    await tester.enterText(find.byType(TextField), 'Hello there');
    await tester.tap(find.text('Send Message'));
    await tester.pumpAndSettle();

    expect(find.text('New Message'), findsNothing);
  });

  testWidgets('shows an error message when the server rejects the message',
      (WidgetTester tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({'message': 'Message contains inappropriate language and was not sent.'}),
        400,
        headers: {'content-type': 'application/json'},
      );
    });

    await tester.pumpWidget(buildCompose(donorId: 4, httpClient: client));

    await tester.enterText(find.byType(TextField), 'a bad word');
    await tester.tap(find.text('Send Message'));
    await tester.pumpAndSettle();

    expect(
      find.text('Message contains inappropriate language and was not sent.'),
      findsOneWidget,
    );
  });
}
