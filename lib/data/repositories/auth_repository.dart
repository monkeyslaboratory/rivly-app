import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient _client = DioClient();
  final SecureStorageService _storage = SecureStorageService();

  Future<UserModel> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.register,
      data: {
        'email': email,
        'username': username,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    await _storage.setAccessToken(data['access'] as String);
    await _storage.setRefreshToken(data['refresh'] as String);

    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data as Map<String, dynamic>;
    await _storage.setAccessToken(data['access'] as String);
    await _storage.setRefreshToken(data['refresh'] as String);

    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<bool> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _client.post(
        ApiConstants.refresh,
        data: {'refresh': refreshToken},
      );

      final data = response.data as Map<String, dynamic>;
      await _storage.setAccessToken(data['access'] as String);
      if (data['refresh'] != null) {
        await _storage.setRefreshToken(data['refresh'] as String);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearTokens();
  }

  Future<UserModel> getMe() async {
    final response = await _client.get(ApiConstants.me);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateMe({
    String? username,
    String? locale,
    String? timezone,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (locale != null) body['locale'] = locale;
    if (timezone != null) body['timezone'] = timezone;

    final response = await _client.patch(ApiConstants.me, data: body);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
