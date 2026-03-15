import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/job_model.dart';
import '../models/competitor_model.dart';

class JobRepository {
  final DioClient _client = DioClient();

  Future<List<JobModel>> getJobs() async {
    final response = await _client.get(ApiConstants.jobs);
    final data = response.data as List<dynamic>;
    return data
        .map((e) => JobModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<JobModel> getJob(String id) async {
    final response = await _client.get(ApiConstants.jobDetail(id));
    final data = response.data as Map<String, dynamic>;
    return JobModel.fromJson(data);
  }

  Future<JobModel> createJob({
    required String name,
    required String productUrl,
    String? productDescription,
    String? productCategory,
    String schedule = 'manual',
    List<Map<String, dynamic>>? competitors,
    List<String>? analysisAreas,
    Map<String, dynamic>? config,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'product_url': productUrl,
      'schedule': schedule,
    };
    if (productDescription != null) {
      body['product_description'] = productDescription;
    }
    if (productCategory != null) body['product_category'] = productCategory;
    if (competitors != null) body['competitors'] = competitors;
    if (analysisAreas != null) body['analysis_areas'] = analysisAreas;
    if (config != null) body['config'] = config;

    final response = await _client.post(ApiConstants.jobs, data: body);
    final data = response.data as Map<String, dynamic>;
    return JobModel.fromJson(data);
  }

  Future<JobModel> updateJob(String id, Map<String, dynamic> updates) async {
    final response =
        await _client.patch(ApiConstants.jobDetail(id), data: updates);
    final data = response.data as Map<String, dynamic>;
    return JobModel.fromJson(data);
  }

  Future<void> deleteJob(String id) async {
    await _client.delete(ApiConstants.jobDetail(id));
  }

  Future<void> triggerRun(String jobId) async {
    await _client.post(ApiConstants.jobRun(jobId));
  }

  Future<Map<String, dynamic>> analyzeProduct(String url) async {
    final response = await _client.post(
      ApiConstants.analyzeProduct,
      data: {'url': url},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<CompetitorModel>> discoverCompetitors({
    required String productUrl,
    String? productDescription,
    String? productCategory,
  }) async {
    final body = <String, dynamic>{
      'product_url': productUrl,
    };
    if (productDescription != null) {
      body['product_description'] = productDescription;
    }
    if (productCategory != null) body['product_category'] = productCategory;

    final response = await _client.post(
      ApiConstants.discoverCompetitors,
      data: body,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => CompetitorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> suggestAreas({
    required String productUrl,
    String? productCategory,
  }) async {
    final body = <String, dynamic>{
      'product_url': productUrl,
    };
    if (productCategory != null) body['product_category'] = productCategory;

    final response = await _client.post(
      ApiConstants.suggestAreas,
      data: body,
    );
    final data = response.data as List<dynamic>;
    return data.map((e) => e as String).toList();
  }

  Future<Map<String, dynamic>> checkAccess(String url) async {
    final response = await _client.post(
      ApiConstants.checkAccess,
      data: {'url': url},
    );
    return response.data as Map<String, dynamic>;
  }
}
