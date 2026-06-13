import 'package:get_it/get_it.dart';
import '../../services/auth_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerLazySingleton<AuthService>(() => AuthService());
  sl.registerLazySingleton<AuthController>(() => AuthController(sl<AuthService>()));
  sl.registerLazySingleton<SettingsController>(() => SettingsController()..loadFromStorage());
}
