/// Ghar ka layout — sirf 3 rooms, aur sensors (flame + smoke) sirf ek room mein.
///
/// Naam badalna ho to bas yahan badal dein, poori app mein khud change ho jayega.
library;

/// Ghar ka naam (home screen aur twin par dikhta hai)
const String kHomeName = 'My Home';

/// Jis room mein flame + smoke sensor lage hain. Alerts sirf isi room ko point karte hain.
const String kMonitoredRoom = 'Bedroom';

/// Ghar ke 3 rooms. Sirf pehla (kMonitoredRoom) monitored hai, baqi do khaali hain.
const List<String> kRoomNames = [kMonitoredRoom, 'Kitchen', 'Living Room'];

const int kRoomCount = 3;

/// Dono sensor ki device IDs (sensors screen par)
const String kFlameSensorId = 'ESP32-FLAME-01';
const String kSmokeSensorId = 'ESP32-SMOKE-01';
