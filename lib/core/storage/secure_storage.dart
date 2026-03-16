import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simple in-memory + localStorage fallback for web.
/// Uses FlutterSecureStorage on mobile, in-memory map on web.
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static final SecureStorageService _instance = SecureStorageService._();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage? _nativeStorage;
  final Map<String, String> _memoryStore = {};

  SecureStorageService._()
      : _nativeStorage = kIsWeb
            ? null
            : const FlutterSecureStorage(
                aOptions: AndroidOptions(encryptedSharedPreferences: true),
              );

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _memoryStore[key];
    }
    return _nativeStorage!.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      _memoryStore[key] = value;
      return;
    }
    await _nativeStorage!.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      _memoryStore.remove(key);
      return;
    }
    await _nativeStorage!.delete(key: key);
  }

  Future<String?> getAccessToken() => _read(_accessTokenKey);
  Future<void> setAccessToken(String token) => _write(_accessTokenKey, token);

  Future<String?> getRefreshToken() => _read(_refreshTokenKey);
  Future<void> setRefreshToken(String token) => _write(_refreshTokenKey, token);

  Future<void> clearTokens() async {
    await _delete(_accessTokenKey);
    await _delete(_refreshTokenKey);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null;
  }
}
