import 'package:flutter/material.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/role_selection_screen.dart';
import '../../features/auth/presentation/pages/auth_choice_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/register_screen.dart';
import '../../features/home/presentation/pages/job_seeker_home.dart';
import '../../features/home/presentation/pages/employer_home.dart';
import '../../features/jobs/presentation/pages/job_detail_screen.dart';
import '../../features/jobs/presentation/pages/create_job_screen.dart';
import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/profile/presentation/pages/employer_setup_screen.dart';
import '../../features/chat/presentation/pages/chat_detail_screen.dart';
import '../../features/jobs/data/models/job_model.dart';

class AppRouter {
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String authChoice = '/auth/choice';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String jobSeekerHome = '/job-seeker/home';
  static const String employerHome = '/employer/home';
  static const String employerSetup = '/employer/setup';
  static const String jobDetail = '/job/detail';
  static const String createJob = '/job/create';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String chatDetail = '/chat/detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());
      case roleSelection:
        return _buildRoute(const RoleSelectionScreen());
      case authChoice:
        final userType = settings.arguments as String? ?? 'job_seeker';
        return _buildRoute(AuthChoiceScreen(userType: userType));
      case login:
        final userType = settings.arguments as String? ?? 'job_seeker';
        return _buildRoute(LoginScreen(userType: userType));
      case register:
        final userType = settings.arguments as String? ?? 'job_seeker';
        return _buildRoute(RegisterScreen(userType: userType));
      case jobSeekerHome:
        return _buildRoute(const JobSeekerHome());
      case employerHome:
        return _buildRoute(const EmployerHome());
      case employerSetup:
        return _buildRoute(const EmployerSetupScreen());
      case jobDetail:
        final job = settings.arguments as JobModel;
        return _buildRoute(JobDetailScreen(job: job));
      case createJob:
        return _buildRoute(const CreateJobScreen());
      case profile:
        return _buildRoute(const ProfileScreen());
      case editProfile:
        return _buildRoute(const EditProfileScreen());
      case chatDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(ChatDetailScreen(
          chatId: (args['chatId'] ?? '').toString(),
          otherUserName: (args['name'] ?? '').toString(),
          otherUserId: (args['otherUserId'] ?? '').toString(),
        ));
      default:
        return _buildRoute(const Scaffold(
          body: Center(child: Text('Səhifə tapılmadı')),
        ));
    }
  }

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
