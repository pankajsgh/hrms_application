
import 'package:hrms/core/common.dart';
import 'package:hrms/core/dio_client.dart';
import 'package:hrms/core/storage_config.dart';
import 'package:hrms/data/datasources/local_datasource.dart';
import 'package:hrms/data/datasources/remote_datasource.dart';
// import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class Repo {
  static final LocalDatasource _local = LocalDatasource();

  static final RemoteDatasource _remote =
  RemoteDatasource(DioClient());

  // ==========================================================
  // CHECK INTERNET CONNECTION
  // ==========================================================

  static Future<bool> isOnline() async {
    try {
      return true;
      // return await InternetConnection().hasInternetAccess;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================
  // GET DATA
  // ==========================================================

  static Future<List<Rec>> queryOrLocal(
      String endpoint,
      Map<String, String> query,
      Future<List<Rec>> Function() localQuery,
      ) async {

    switch (StorageConfig.mode) {
      case StorageMode.localOnly:
        return await _local.fetchData(localQuery);

      case StorageMode.apiOnly:
        return await _remote.fetchData(endpoint, query);

      case StorageMode.localAndApi:
        final online = await isOnline();

        if (online) {
          try {
            return await _remote.fetchData(endpoint, query);
          } catch (e) {
            return await _local.fetchData(localQuery);
          }
        }

        return await _local.fetchData(localQuery);
    }
  }

  // ==========================================================
  // ADD / UPDATE DATA
  // ==========================================================

  static Future<int> saveData(
      String tableOrEndpoint,
      Map<String, String> query,
      Map<String, Object?> data,
      ) async {
    switch (StorageConfig.mode) {
      case StorageMode.localOnly:
        return await _local.saveData(
          tableOrEndpoint,
          query,
          data,
        );

      case StorageMode.apiOnly:
        return await _remote.saveData(
          tableOrEndpoint,
          query,
          data,
        );

      case StorageMode.localAndApi:
      // First save in SQLite.
        final localId = await _local.saveData(
          tableOrEndpoint,
          query,
          data,
        );

        if (localId <= 0) return localId;

        // Check internet.
        final online = await isOnline();

        // Offline: SQLite only.
        if (!online) return localId;

        // Online: save in API.
        try {
          await _remote.saveData(
            tableOrEndpoint,
            query,
            data,
          );
        } catch (e) {
          // Local data remains saved.
          // Pending sync will be handled separately.
        }

        return localId;
    }
  }

  // ==========================================================
  // DELETE DATA
  // ==========================================================

  static Future<int> deleteData(
      String tableOrEndpoint,
      Map<String, String> query,
      ) async {
    switch (StorageConfig.mode) {
      case StorageMode.localOnly:
        return await _local.deleteData(
          tableOrEndpoint,
          query,
        );

      case StorageMode.apiOnly:
        return await _remote.deleteData(
          tableOrEndpoint,
          query,
        );

      case StorageMode.localAndApi:
      // First delete from SQLite.
        final localCount = await _local.deleteData(
          tableOrEndpoint,
          query,
        );

        if (localCount <= 0) return localCount;

        // Check internet.
        final online = await isOnline();

        // Offline: SQLite only.
        if (!online) return localCount;

        // Online: delete from API.
        try {
          await _remote.deleteData(
            tableOrEndpoint,
            query,
          );
        } catch (e) {
          // Local deletion remains completed.
          // Pending sync will be handled separately.
        }

        return localCount;
    }
  }
}
