
import 'package:hrms/core/common.dart';
import 'package:hrms/core/dio_client.dart';

class RemoteDatasource {
  final DioClient _dioClient;

  RemoteDatasource(this._dioClient);

  Future<List<Rec>> fetchData(String endpoint, Map<String, String> query) async {
    try {
      final response = await _dioClient.get('/$endpoint', queryParameters: query);
      if (response.data is List) {
        return List<Rec>.from((response.data as List).map((x) => Map<String, Object?>.from(x)));
      } else if (response.data is Map && response.data['data'] is List) {
        return List<Rec>.from((response.data['data'] as List).map((x) => Map<String, Object?>.from(x)));
      }
      return [];
    } catch (e) {
      // If API fails or in local-only / test mode without backend
      return [];
    }
  }

  Future<int> saveData(String endpoint, Map<String, String> query, Map<String, Object?> data) async {
    try {
      final response = await _dioClient.post('/$endpoint', queryParameters: query, data: data);
      if (response.data is Map && response.data['id'] != null) {
        return (response.data['id'] as num).toInt();
      }
      return 1;
    } catch (e) {
      return -1;
    }
  }

  Future<int> deleteData(String endpoint, Map<String, String> query) async {
    try {
      await _dioClient.delete('/$endpoint', queryParameters: query);
      return 1;
    } catch (e) {
      return 0;
    }
  }
}
