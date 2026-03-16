class ApiConstants {
  static const baseUrl = 'http://localhost:8000/api/v1';
  static const wsUrl = 'ws://localhost:8001/ws';

  // Auth
  static const register = '$baseUrl/auth/register/';
  static const login = '$baseUrl/auth/login/';
  static const refresh = '$baseUrl/auth/refresh/';
  static const me = '$baseUrl/auth/me/';

  // Jobs
  static const jobs = '$baseUrl/jobs/';
  static String jobDetail(String id) => '$baseUrl/jobs/$id/';
  static String jobRun(String id) => '$baseUrl/jobs/$id/run/';

  // Stepper
  static const analyzeProduct = '$baseUrl/jobs/stepper/analyze-product/';
  static const discoverCompetitors =
      '$baseUrl/jobs/stepper/discover-competitors/';
  static const suggestAreas = '$baseUrl/jobs/stepper/suggest-areas/';
  static const checkAccess = '$baseUrl/jobs/stepper/check-access/';

  // Runs
  static String runs(String jobId) => '$baseUrl/runs/jobs/$jobId/runs/';
  static String runDetail(String id) => '$baseUrl/runs/$id/';
  static String runReport(String id) => '$baseUrl/runs/$id/report/';
  static String screenshotImage(String id) => '$baseUrl/runs/screenshots/$id/';

  // WebSocket
  static String wsRun(String runId, String token) =>
      '$wsUrl/runs/$runId/?token=$token';
}
