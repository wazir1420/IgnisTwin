/// App data kahan se le: fake demo data, Firebase, ya seedha ESP32 (local WiFi)
enum DataSource { dummy, firebase, esp32 }

extension DataSourceX on DataSource {
  String get label => switch (this) {
        DataSource.dummy => 'Dummy',
        DataSource.firebase => 'Firebase',
        DataSource.esp32 => 'ESP32',
      };
}
