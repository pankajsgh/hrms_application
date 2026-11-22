import 'package:hrms/core/common.dart';

import '../../core/storage_config.dart';
import '../../core/dio_client.dart';
import '../../domain/repositories/base_repository.dart';
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';

class RepositoryImpl implements BaseRepository {
  final String tableOrEndpoint;
  final LocalDatasource localDatasource;
  final RemoteDatasource remoteDatasource;

  RepositoryImpl(this.tableOrEndpoint)
      : localDatasource = LocalDatasource(),
        remoteDatasource = RemoteDatasource(DioClient());

  @override
  Future<List<Rec>> fetchData(Map<String, String> query) async {
    if (StorageConfig.mode == StorageMode.apiOnly) {
      return await remoteDatasource.fetchData(tableOrEndpoint, query);
    } else if (StorageConfig.mode == StorageMode.localAndApi) {
      try {
        final remoteData = await remoteDatasource.fetchData(tableOrEndpoint, query);
        if (remoteData.isNotEmpty) {
          // Cache locally if needed
          return remoteData;
        }
      } catch (_) {}
    }
    // Default or localOnly
    return await LocalDatasource.fetchData(tableOrEndpoint, query);
  }

  @override
  Future<int> saveData(Map<String, String> query, Map<String, Object?> data) async {
    int id = 0;
    if (StorageConfig.mode != StorageMode.apiOnly) {
      id = await LocalDatasource.saveData(tableOrEndpoint, query, data);
    }
    if (StorageConfig.mode == StorageMode.apiOnly || StorageConfig.mode == StorageMode.localAndApi) {
      try {
        final remoteId = await remoteDatasource.saveData(tableOrEndpoint, query, data);
        if (remoteId > 0) id = remoteId;
      } catch (_) {}
    }
    return id;
  }

  @override
  Future<int> deleteData(Map<String, String> query) async {
    int count = 0;
    if (StorageConfig.mode != StorageMode.apiOnly) {
      count = await LocalDatasource.deleteData(tableOrEndpoint, query);
    }
    if (StorageConfig.mode == StorageMode.apiOnly || StorageConfig.mode == StorageMode.localAndApi) {
      try {
        await remoteDatasource.deleteData(tableOrEndpoint, query);
      } catch (_) {}
    }
    return count;
  }
}
