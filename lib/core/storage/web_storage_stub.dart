/// Stub for non-web platforms. Never actually called on mobile.
class WebStorage {
  static String? read(String key) => null;
  static void write(String key, String value) {}
  static void delete(String key) {}
}
