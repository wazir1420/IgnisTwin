
enum DataSource { firebase, esp32 }

extension DataSourceX on DataSource {
  String get label => switch (this) {
    DataSource.firebase => 'Cloud connection',
    DataSource.esp32 => 'Direct device connection',
  };
}
