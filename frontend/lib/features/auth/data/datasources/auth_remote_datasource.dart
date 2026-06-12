import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio _dio = ApiClient.instance;

  Future<({UserModel user, String accessToken, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data['data'];
    return (
      user: UserModel.fromJson(data['user']),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<({UserModel user, String accessToken, String refreshToken})> register({
    required String fullName,
    required String email,
    required String password,
    String? bloodType,
    String? gender,
    String? phone,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        if (bloodType != null) 'bloodType': bloodType,
        if (gender != null) 'gender': gender,
        if (phone != null) 'phone': phone,
      },
    );
    final data = response.data['data'];
    return (
      user: UserModel.fromJson(data['user']),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data['data']);
  }
}
