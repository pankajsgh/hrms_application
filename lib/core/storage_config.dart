enum StorageMode {
  localOnly,
  apiOnly,
  localAndApi, // Saves locally and syncs/saves via Dio API
}

class StorageConfig {
  static StorageMode mode = StorageMode.localOnly;
  static String apiUrl = 'http://127.0.0.1:8080/api'; // configurable base url for Dio API

  static void setMode(StorageMode newMode) {
    mode = newMode;
  }
}
