import 'package:flutter_test/flutter_test.dart';
import 'package:ignistwin/models/risk_level.dart';
import 'package:ignistwin/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('smoke warning starts at the configured threshold', () {
    final provider = AppProvider();
    addTearDown(provider.dispose);

    provider.updateSim(f: false, s: 1125);
    provider.setSimulation(true);
    expect(provider.level, RiskLevel.normal);

    provider.updateSim(s: 1499);
    expect(provider.level, RiskLevel.normal);

    provider.updateSim(s: 1500);
    expect(provider.level, RiskLevel.warning);
  });
}
