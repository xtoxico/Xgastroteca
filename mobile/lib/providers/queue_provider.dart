import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile/core/constants/app_config.dart';
import 'package:mobile/models/queue_job.dart';

part 'queue_provider.g.dart';

@riverpod
class Queue extends _$Queue {
  @override
  Future<List<QueueJob>> build() async {
    return fetchQueue();
  }

  Future<List<QueueJob>> fetchQueue() async {
    final dio = Dio();
    try {
      final response = await dio.get('${AppConfig.apiBaseUrl}/api/queue');
      final List<dynamic> data = response.data;
      return data.map((json) => QueueJob.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load queue: $e');
    }
  }

  Future<void> deleteJob(int id) async {
    final dio = Dio();
    try {
      await dio.delete('${AppConfig.apiBaseUrl}/api/queue/$id');
      // Refresh list
      ref.invalidateSelf();
    } catch (e) {
      throw Exception('Failed to delete job: $e');
    }
  }
}
