enum StorageMode {
  localOnly,
  apiOnly,
  localAndApi, // Saves locally and syncs/saves via Dio API
}

class StorageConfig {
  static StorageMode mode = StorageMode.localOnly;
  static String apiUrl = 'https://api.example.com/v1'; // configurable base url for Dio API

  static void setMode(StorageMode newMode) {
    mode = newMode;
  }
}
