/// Firebase project ka ID (console ke URL mein: /project/ignistwin/...)
const String kFirebaseProjectId = 'ignistwin';

/// Firebase console -> Realtime Database -> upar likha URL yahan paste karein.
/// Region ke hisab se ye kuch aisa hota hai:
///   https://myproject-default-rtdb.firebaseio.com
///   https://myproject-default-rtdb.asia-southeast1.firebasedatabase.app
/// (Bilkul wahi URL jo ESP32 code mein bhi dala hai, bina "/" ke end mein)
const String kDatabaseUrl =
    'https://ignistwin-default-rtdb.asia-southeast1.firebasedatabase.app';

/// ESP32 itne milliseconds se zyada purana data bheje to sensor OFFLINE maana jaye.
///
/// ESP32 aam tor par har 6-12 second update karta hai, is liye 15s threshold bohot
/// tight tha (ek update chhoote hi app offline dikha deti thi). 60s = ~5 miss hone
/// par hi offline, aur network ki chhoti rukawat se alert nahi aata.
const int kStaleAfterMs = 60000;
