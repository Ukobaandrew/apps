import 'package:flutter/material.dart';
import 'package:taskwin/features/auth/screens/0nboarding_screen.dart'; // note lowercase 'o'
import 'package:taskwin/screens/splash_screen.dart';
import 'package:taskwin/features/auth/screens/login_screen.dart';
import 'package:taskwin/features/auth/screens/sign_up_screen.dart'; // <-- added
import 'package:taskwin/screens/main_screen.dart';
import 'package:taskwin/features/tasks/screens/task_detail_screen.dart';
import 'package:taskwin/features/join/screens/join_task_screen.dart';
import 'package:taskwin/features/voting/screens/voting_screen.dart';
import 'package:taskwin/features/results/screens/results_screen.dart';
import 'package:taskwin/features/tasks/models/task_model.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/':
      case '/main':
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/sign-up': // optional – if you want to navigate via named route
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/task-details':
        final taskId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: taskId),
        );
      case '/join-task':
        final task = settings.arguments as TaskModel;
        return MaterialPageRoute(
          builder: (_) => JoinTaskScreen(task: task),
        );
      case '/voting':
        final task = settings.arguments as TaskModel;
        return MaterialPageRoute(
          builder: (_) => VotingScreen(task: task),
        );
      case '/results':
        final task = settings.arguments as TaskModel;
        return MaterialPageRoute(
          builder: (_) => ResultsScreen(task: task),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
