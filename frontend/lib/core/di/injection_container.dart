import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource());

  // Blocs
  sl.registerFactory<AuthBloc>(() => AuthBloc(sl<AuthRemoteDataSource>()));
}
