import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/run_model.dart';

class RunRepository {
  final DioClient _client = DioClient();

  Future<List<RunModel>> getRuns(String jobId) async {
    final response = await _client.get(ApiConstants.runs(jobId));
    final data = response.data;
    final List<dynamic> results;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      results = [];
    }
    return results
        .map((e) => RunModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RunModel> getRun(String id) async {
    final response = await _client.get(ApiConstants.runDetail(id));
    final data = response.data as Map<String, dynamic>;
    return RunModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getRawRun(String id) async {
    final response = await _client.get(ApiConstants.runDetail(id));
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelRun(String id) async {
    await _client.post('${ApiConstants.runDetail(id)}cancel/');
  }

  Future<void> approveRun(String runId, {List<String> removeIds = const []}) async {
    await _client.post('${ApiConstants.runDetail(runId)}approve/', data: {
      'remove_screenshot_ids': removeIds,
    });
  }

  Future<List<Map<String, dynamic>>> addPages(String runId, List<String> urls) async {
    final response = await _client.post('${ApiConstants.runDetail(runId)}add-pages/', data: {
      'urls': urls,
    });
    return (response.data['added'] as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
  }

  Future<void> submitVerificationCode(String runId, String code) async {
    await _client.post('${ApiConstants.runDetail(runId)}submit-code/', data: {
      'code': code,
    });
  }

  Future<Map<String, dynamic>> startBrowserSession(String runId, {String? loginUrl}) async {
    final response = await _client.post(ApiConstants.browserSession(runId), data: {
      if (loginUrl != null) 'login_url': loginUrl,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> submitAuthCredentials(String runId, {
    required String email,
    required String password,
    String? loginUrl,
  }) async {
    await _client.post('${ApiConstants.runDetail(runId)}auth-crawl/', data: {
      'credentials': {
        'email': email,
        'password': password,
        if (loginUrl != null && loginUrl.isNotEmpty) 'login_url': loginUrl,
      },
    });
  }
}
