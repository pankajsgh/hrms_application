
import 'package:dio/dio.dart';
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


  Future<int> saveData(
      String endpoint,
      Map<String, String> query,
      Map<String, Object?> data,
      ) async {
    try {
      var response;
      if (query.isEmpty) {
        response = await _dioClient.post(
          '/$endpoint',
          queryParameters: query,
          data: data,
        );
      } else {

        final id =query['id'] ?? '';
        response = await _dioClient.put(
          '/$endpoint/$id',
          data: data,
        );
      }


      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map && responseData['id'] != null) {
          return (responseData['id'] as num).toInt();
        }
        return 1;
      }

      return -1;
    } on DioException catch (e) {
      print('API Error 11: ${e.response?.data ?? e.message}');
      return -1;
    } catch (e) {
      print('Save Error: $e');
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
