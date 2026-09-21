import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/task/task_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/task_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final storageService = await StorageService.init();
  final authService = AuthService(storageService);
  final taskService = TaskService(storageService);

  runApp(TaskFlowApp(
    storageService: storageService,
    authService: authService,
    taskService: taskService,
  ));
}

class TaskFlowApp extends StatelessWidget {
  final StorageService storageService;
  final AuthService authService;
  final TaskService taskService;

  const TaskFlowApp({
    super.key,
    required this.storageService,
    required this.authService,
    required this.taskService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(storageService),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authService)
            ..add(const AuthCheckSessionRequested()),
        ),
        BlocProvider<TaskBloc>(
          create: (_) => TaskBloc(taskService),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'TaskFlow',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const AppRootNavigator(),
          );
        },
      ),
    );
  }
}

class AppRootNavigator extends StatelessWidget {
  const AppRootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      listener: (context, state) {
        // Handle session changes or notifications
      },
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainNavigationScreen();
        }

        if (state is AuthLoading && state is! AuthError) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const LoginScreen();
      },
    );
  }
}
