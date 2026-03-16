import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/run_model.dart';
import '../models/report_model.dart';

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

  Future<ReportModel> getReport(String runId) async {
    final response = await _client.get(ApiConstants.runReport(runId));
    final data = response.data as Map<String, dynamic>;
    return ReportModel.fromJson(data);
  }

  Future<void> cancelRun(String id) async {
    await _client.post('${ApiConstants.runDetail(id)}cancel/');
  }
}
