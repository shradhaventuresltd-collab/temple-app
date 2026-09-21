import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temple_app/services/seed_service.dart';
import 'package:temple_app/widgets/seed_temples_control.dart';

void main() {
  testWidgets('panel shows idle, running, then success', (tester) async {
    final gate = Completer<SeedResult>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SeedTemplesControl(seed: () => gate.future),
          ),
        ),
      ),
    );

    expect(find.text('No temples in Firestore'), findsOneWidget);
    expect(find.text('Seed sample temples'), findsOneWidget);

    await tester.tap(find.text('Seed sample temples'));
    await tester.pump();

    expect(find.text('Seeding…'), findsOneWidget);
    expect(find.text('Seeding sample temples…'), findsOneWidget);

    gate.complete(
      const SeedResult(writtenCount: 30, createdCount: 30, updatedCount: 0),
    );
    await tester.pump();

    expect(find.text('Seeded 30 temples into Firestore.'), findsOneWidget);
    expect(find.text('Seed again'), findsOneWidget);
  });

  testWidgets('panel shows a short error and retry on failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SeedTemplesControl(
              seed: () async => throw Exception('permission-denied'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seed sample temples'));
    await tester.pump();

    expect(find.text('permission-denied'), findsOneWidget);
    expect(find.text('Retry seed'), findsOneWidget);
  });

  testWidgets('compact control reports running and success', (tester) async {
    final gate = Completer<SeedResult>();
    var successCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SeedTemplesControl(
                compact: true,
                seed: () => gate.future,
                onSuccess: () => successCount++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Seed'), findsOneWidget);

    await tester.tap(find.text('Seed'));
    await tester.pump();

    expect(find.text('Seeding'), findsOneWidget);

    gate.complete(
      const SeedResult(writtenCount: 30, createdCount: 0, updatedCount: 30),
    );
    await tester.pump();

    expect(find.text('Seeded'), findsOneWidget);
    expect(successCount, 1);
    expect(
      find.text('Updated 30 existing sample temples. No duplicates created.'),
      findsOneWidget,
    );
  });

  testWidgets('blocked compact Seed does not write and shows a clear message',
      (tester) async {
    var seedCalls = 0;
    var unauthorizedCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SeedTemplesControl(
                compact: true,
                canWrite: false,
                seed: () async {
                  seedCalls++;
                  return const SeedResult(
                    writtenCount: 0,
                    createdCount: 0,
                    updatedCount: 0,
                  );
                },
                onUnauthorized: () => unauthorizedCalls++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Seed'));
    await tester.pump();

    expect(seedCalls, 0);
    expect(unauthorizedCalls, 1);
    expect(
      find.text(
        'Sign in as an admin (custom claim admin: true) to seed Firestore.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('blocked panel Seed shows lock state and does not write',
      (tester) async {
    var seedCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SeedTemplesControl(
              canWrite: false,
              seed: () async {
                seedCalls++;
                return const SeedResult(
                  writtenCount: 0,
                  createdCount: 0,
                  updatedCount: 0,
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Admin sign-in required to seed'), findsOneWidget);
    expect(find.text('Seed sample temples'), findsNothing);
    expect(seedCalls, 0);
  });
}
