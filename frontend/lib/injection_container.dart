import 'package:get_it/get_it.dart';
import 'package:news_app_clean_architecture/di/articles_di.dart';
import 'package:news_app_clean_architecture/di/auth_di.dart';
import 'package:news_app_clean_architecture/di/core_di.dart';
import 'package:news_app_clean_architecture/di/daily_news_di.dart';
import 'package:news_app_clean_architecture/di/user_profile_di.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  await registerCoreDependencies(sl);
  registerAuthDependencies(sl);
  registerUserProfileDependencies(sl);
  registerDailyNewsDependencies(sl);
  registerArticlesDependencies(sl);
}
