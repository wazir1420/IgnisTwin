/// Firebase project ka ID (console ke URL mein: /project/ignistwin/...)
const String kFirebaseProjectId = 'ignistwin';

/// Firebase console -> Realtime Database -> upar likha URL yahan paste karein.
/// Region ke hisab se ye kuch aisa hota hai:
///   https://myproject-default-rtdb.firebaseio.com
///   https://myproject-default-rtdb.asia-southeast1.firebasedatabase.app
/// (Bilkul wahi URL jo ESP32 code mein bhi dala hai, bina "/" ke end mein)
const String kDatabaseUrl =
    'https://ignistwin-default-rtdb.asia-southeast1.firebasedatabase.app';

/// ESP32 itne milliseconds se zyada purana data bheje to sensor OFFLINE maana jaye
const int kStaleAfterMs = 15000;
