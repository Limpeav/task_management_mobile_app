import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_management_app/main.dart';
import 'package:task_management_app/models/user_model.dart';
import 'package:task_management_app/screens/auth/login_screen.dart';
import 'package:task_management_app/screens/main_navigation_screen.dart';
import 'package:task_management_app/services/auth_service.dart';
import 'package:task_management_app/services/storage_service.dart';
import 'package:task_management_app/services/task_service.dart';

void main() {
  testWidgets('Unauthenticated launch renders LoginScreen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final authService = AuthService(storageService);
    final taskService = TaskService(storageService);

    await tester.pumpWidget(
      TaskFlowApp(
        storageService: storageService,
        authService: authService,
        taskService: taskService,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Quick Demo Login (1-Click)'), findsOneWidget);
  });

  testWidgets('Authenticated user launch renders MainNavigationScreen & Dashboard',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    // Set active user session
    final demoUser = AppUser(
      id: 'demo_user_001',
      email: 'alex@example.com',
      displayName: 'Alex Morgan',
      createdAt: DateTime.now(),
    );
    await storageService.setCurrentUser(demoUser);

    final authService = AuthService(storageService);
    final taskService = TaskService(storageService);

    await tester.pumpWidget(
      TaskFlowApp(
        storageService: storageService,
        authService: authService,
        taskService: taskService,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Total Tasks'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);

    // Switch to Tasks tab
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('All Tasks'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    // Switch to Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });
}
