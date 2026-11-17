/*
  IgnisTwin - ESP32 -> Firebase Realtime Database
  Aap ke pins:
    Flame : DO -> GPIO 27, AO -> GPIO 34
    Smoke : DO -> GPIO 26, AO -> GPIO 35
  Extra library ki zaroorat nahi.
*/
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>

// ====== APNE WIFI / DEVICE KI VALUES BHAREIN ======
const char* WIFI_SSID = "Wazir";
const char* WIFI_PASS = "wazir@1420";
const char* DB_URL    = "https://ignistwin-default-rtdb.asia-southeast1.firebasedatabase.app";
const char* DEVICE_ID = "ESP32-BEDROOM-01";
// ================================================================

#define FLAME_DO 27
#define FLAME_AO 34
#define SMOKE_DO 26
#define SMOKE_AO 35

// Aksar modules detection par LOW dete hain
#define FLAME_ACTIVE LOW
#define SMOKE_ACTIVE LOW

#define SEND_INTERVAL_MS 2000

unsigned long lastSend = 0;

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("WiFi connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nConnected, IP: " + WiFi.localIP().toString());
}

void setup() {
  Serial.begin(115200);

  pinMode(FLAME_DO, INPUT);
  pinMode(SMOKE_DO, INPUT);
  analogReadResolution(12);   // 0 - 4095

  Serial.println("================================");
  Serial.println("Flame & Smoke Detection System");
  Serial.println("================================");
  Serial.println("Device ID: " + String(DEVICE_ID));
  Serial.println("MQ-2 sensor ko warm-up hone dein.");

  connectWiFi();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  if (millis() - lastSend < SEND_INTERVAL_MS) return;
  lastSend = millis();

  // ---- readings ----
  int flameDigital = digitalRead(FLAME_DO);
  int flameAnalog  = analogRead(FLAME_AO);
  int smokeDigital = digitalRead(SMOKE_DO);
  int smokeAnalog  = analogRead(SMOKE_AO);

  bool flame      = (flameDigital == FLAME_ACTIVE);
  bool smokeAlert = (smokeDigital == SMOKE_ACTIVE);

  // ---- serial monitor (calibration ke liye bohat kaam ki) ----
  Serial.println("\n------ SENSOR READINGS ------");
  Serial.println("Flame Analog: " + String(flameAnalog) + " | Digital: " + String(flameDigital));
  Serial.println(flame ? "ALERT: FIRE DETECTED!" : "No Fire Detected");
  Serial.println("Smoke Analog: " + String(smokeAnalog) + " | Digital: " + String(smokeDigital));
  Serial.println(smokeAlert ? "ALERT: SMOKE DETECTED!" : "No Smoke Detected");

  // ---- Write device readings; admin assigns this ID to a user ----
  String json = "{\"flame\":" + String(flame ? "true" : "false") +
                ",\"smoke\":" + String(smokeAnalog) +
                ",\"smokeAlert\":" + String(smokeAlert ? "true" : "false") +
                ",\"flameAnalog\":" + String(flameAnalog) +
                ",\"lastSeen\":{\".sv\":\"timestamp\"}}";

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;
  http.setTimeout(5000);
  const String path = String(DB_URL) + "/devices/" + DEVICE_ID +
                      "/sensordata.json";
  if (!http.begin(client, path)) {
    Serial.println("Firebase connection setup failed");
    return;
  }
  http.addHeader("Content-Type", "application/json");
  int code = http.PUT(json);
  Serial.println("Firebase HTTP " + String(code) + (code == 200 ? "  (OK)" : "  (ERROR)"));
  http.end();
}
