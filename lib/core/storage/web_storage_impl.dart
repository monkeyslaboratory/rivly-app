// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebStorage {
  static String? read(String key) {
    return html.window.localStorage[key];
  }

  static void write(String key, String value) {
    html.window.localStorage[key] = value;
  }

  static void delete(String key) {
    html.window.localStorage.remove(key);
  }
}
