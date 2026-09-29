import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_nightlife/main.dart';

void main() {
  testWidgets('user can create an account and see seeded events', (tester) async {
    await tester.pumpWidget(const MadNightlifeApp());
    await tester.tap(find.text('New here? Create an account'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('display-name')), 'Alex');
    await tester.enterText(find.byKey(const Key('email')), 'alex@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'secret1');
    await tester.tap(find.text('Create account'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Explore events'), findsOneWidget);
    expect(find.text('Midnight Mix'), findsOneWidget);
    expect(find.text('City Lights Social'), findsOneWidget);
  });

  testWidgets('invalid sign in shows validation error', (tester) async {
    await tester.pumpWidget(const MadNightlifeApp());
    await tester.enterText(find.byKey(const Key('email')), 'not-an-email');
    await tester.enterText(find.byKey(const Key('password')), 'short');
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('auth-error')), findsOneWidget);
    expect(find.textContaining('valid email'), findsOneWidget);
  });

  testWidgets('attendee can view details and register', (tester) async {
    final repository = LocalRepository()..signedIn = true;
    repository.profile = UserProfile(displayName: 'Alex', goal: 'Meet new people');
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          profile: repository.profile!,
          onSignOut: () {},
        ),
      ),
    );
    await tester.tap(find.text('Midnight Mix'));
    await tester.pumpAndSettle();
    expect(find.text('Event details'), findsOneWidget);
    await tester.tap(find.text('Register for this event'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('You are registered'), findsOneWidget);
  });

  testWidgets('insufficient matches are explained', (tester) async {
    final repository = LocalRepository()..signedIn = true;
    repository.profile = UserProfile(displayName: 'Alex', goal: '');
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: repository,
          profile: repository.profile!,
          onSignOut: () {},
        ),
      ),
    );
    await tester.tap(find.text('Slow Sunday'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not have enough compatible matches'), findsOneWidget);
    expect(find.text('Event full'), findsOneWidget);
  });
}
