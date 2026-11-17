/// App data kahan se le: Firebase (real sensors) ya seedha ESP32 (local WiFi)
enum DataSource { firebase, esp32 }

extension DataSourceX on DataSource {
  String get label => switch (this) {
    DataSource.firebase => 'Firebase',
    DataSource.esp32 => 'ESP32',
  };
}
