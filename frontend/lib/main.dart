import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app_clean_architecture/config/routes/routes.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:news_app_clean_architecture/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_app_clean_architecture/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:news_app_clean_architecture/features/user_profile/presentation/cubit/user_profile_cubit.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/bottom_nav_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/multi_game_event.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_bloc.dart';
import 'package:news_app_clean_architecture/features/la_loba/presentation/bloc/participant_event.dart';
import 'config/theme/app_themes.dart';
import 'features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDependencies();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RemoteArticlesBloc>(
          create: (context) => sl(),
        ),
        BlocProvider<AuthCubit>(create: (context) => sl()..checkCurrentUser()),
        BlocProvider<UserProfileCubit>(create: (context) => sl()),
        BlocProvider<BottomNavBloc>(create: (context) => sl()),
        BlocProvider<MultiGameBloc>(
          create: (context) => sl()..add(LoadGamesEvent()),
        ),
        BlocProvider<ParticipantBloc>(
          create: (context) => sl()..add(CheckAdminStatusEvent()),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is AuthAuthenticated ||
              authState is AuthUnauthenticated) {
            context.read<ParticipantBloc>().add(const CheckAdminStatusEvent());
          }
        },
        child: MaterialApp(
          title: 'MultiApp',
          debugShowCheckedModeBanner: false,
          theme: theme(),
          onGenerateRoute: AppRoutes.onGenerateRoutes,
          home: const DashboardPage(),
        ),
      ),
    );
  }
}
