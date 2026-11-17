# IgnisTwin

Flutter smoke/fire monitoring app using Firebase Authentication and
Firebase Realtime Database.

## Realtime Database structure

There is one `users` root for app accounts. Each Firebase Auth UID contains
that user's assigned device records. Live readings use a stable global device
ID so an ESP32 can start sending data before an admin assigns it:

```json
{
  "users": {
    "YAHYA_FIREBASE_AUTH_UID": {
      "name": "Yahya",
      "email": "yahya@example.com",
      "phone": "+1 555 0100",
      "photoBase64": "BASE64_ENCODED_JPEG_TEXT",
      "role": "user",
      "accessStatus": "approved",
      "devices": {
        "ESP32-BEDROOM-01": {
          "name": "Bedroom smoke and fire sensor",
          "zone": "Bedroom",
          "enabled": true
        }
      }
    }
  },
  "devices": {
    "ESP32-BEDROOM-01": {
      "ownerUid": "YAHYA_FIREBASE_AUTH_UID",
      "sensordata": {
        "flame": false,
        "smoke": 0,
        "lastSeen": 0
      }
    }
  }
}
```

The profile drawer reads these fields from `users/{uid}`. Users can update their
own name, phone number, and an optional compressed profile photo; the photo is
stored as Base64 text in Realtime Database (not Firebase Storage). Publish the
updated `database.rules.json` rules to allow only the signed-in user to edit
these profile fields.

Replace `FIREBASE_AUTH_UID` with the exact UID shown under Firebase
Authentication. Roles are `admin` and `user`. Public signup always writes the
`user` role; the first admin must be bootstrapped manually in Firebase Console.

The ESP32 writes directly to `/devices/{deviceId}/sensordata` without Firebase
Authentication. This path is publicly writable so the board needs no Firebase
email/password; sensor reads remain limited to admins and the assigned,
approved user. The admin dashboard discovers live unassigned device IDs,
registers their name/room, and assigns them. Assignment records live under
`users/{uid}/devices/{deviceId}`. The user app listens only to its own assigned
devices. Device status is online only if a reading arrived within two minutes.
Admins can reassign or remove a device and remove a user's Realtime Database
profile from the dashboard. Removing a profile also unassigns its devices; the
Firebase Authentication account itself must be removed separately in Firebase
Console or through a trusted Admin SDK backend. Removing a device clears its
current readings and assignment, but a still-running ESP32 can write new
readings again as an unassigned live device.

## Firebase setup

1. Enable Email/Password in Firebase Authentication.
2. In Realtime Database, use the same database URL configured in
   `lib/core/app_config.dart`.
3. Replace the Realtime Database Rules with `database.rules.json`. From the
   project root you can deploy them using:
   `firebase deploy --only database --project ignistwin`
4. Create an account in the app using **Request Access**. It remains pending
   until an administrator approves it.
5. In Authentication, copy that account's UID. In Realtime Database, add
   `users/{UID}` with `name`, `email`, and `role: "admin"`. Admin accounts do
   not require email verification and open the admin dashboard after sign-in.
6. Sign in as an admin and approve user accounts in the Admin Dashboard. Approved
   users can then sign in to the monitoring workspace.
7. In `sketch_nov11a_kanwal.ino`, set `DEVICE_ID` to a unique ID and fill in
   the Wi-Fi name/password. The sketch writes to `/devices/{deviceId}/sensordata`;
   it does not sign in to Firebase.
8. Start the ESP32 and refresh the admin dashboard. Choose the detected live
   device, enter its name and room, and assign it to an approved app user.

These rules let users read their own profile and sensor data; sensor data is
accessible only to admins and the assigned approved user. Admins can manage
profiles and assignments. A user cannot approve their own account or promote
their own profile to admin. Before publishing the new rules, back up existing
data and migrate devices/assignments so device metadata is stored under the
owning `users/{uid}/devices/{deviceId}` node and live sensor data is at
`devices/{deviceId}/sensordata`.

## Sensor integration note

Because unauthenticated direct writes are enabled, anyone who learns the
database URL and a device ID can forge or overwrite its readings. Use unique,
non-guessable device IDs and do not expose them publicly. For stronger
protection, use authenticated devices or a trusted server gateway. This
This app is not a certified replacement for listed fire detection or
life-safety systems.
