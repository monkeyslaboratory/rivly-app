import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/job_model.dart';
import '../models/competitor_model.dart';

class JobRepository {
  final DioClient _client = DioClient();

  Future<List<JobModel>> getJobs() async {
    final response = await _client.get(ApiConstants.jobs);
    final data = response.data;
    // Handle both paginated and list responses
    final List<dynamic> results;
    if (data is Map<String, dynamic> && data.containsKey('results')) {
      results = data['results'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      results = [];
    }
    return results
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
    List<String> areas = const [],
    String deviceType = 'desktop',
    String scheduleFrequency = 'weekly',
  }) async {
    final response = await _client.post(ApiConstants.jobs, data: {
      'name': name,
      'product_url': productUrl,
      'areas': areas,
      'device_type': deviceType,
      'schedule_frequency': scheduleFrequency,
    });
    final data = response.data as Map<String, dynamic>;
    return JobModel.fromJson(data);
  }

  Future<void> addCompetitor(String jobId, String name, String url) async {
    await _client.post('${ApiConstants.jobDetail(jobId)}competitors/', data: {
      'name': name,
      'url': url,
    });
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
    final data = response.data;
    final List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map && data.containsKey('competitors')) {
      items = data['competitors'] as List<dynamic>;
    } else {
      items = [];
    }
    return items
        .map((e) => CompetitorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> discoverCompetitorsRaw({
    required String productUrl,
  }) async {
    final response = await _client.post(
      ApiConstants.discoverCompetitors,
      data: {'product_url': productUrl},
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    if (data is Map && data.containsKey('competitors')) {
      return (data['competitors'] as List).map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
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
