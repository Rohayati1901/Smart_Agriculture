#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <time.h>

// ================= WIFI =================
#define WIFI_SSID "SmartAgri-Setup"
#define WIFI_PASSWORD "12345678"

// ================= FIREBASE =================
#define API_KEY "AIzaSyDYQC80Hr05PKLxWtGEMXtNxXec6HHDQB4"
#define DATABASE_URL "https://smart-agriculture-sliyeg-default-rtdb.asia-southeast1.firebasedatabase.app"
#define USER_EMAIL "sliyeg@gmail.com"
#define USER_PASSWORD "qwertyuiop"

// ================= DEVICE =================
#define DEVICE_ID "smart_agriculture_003"

// ================= PIN =================
#define DHTPIN 12
#define DHTTYPE DHT22
#define SOIL_PIN 34
#define RELAY_PIN 14

// ================= TIME =================
const long GMT_OFFSET_SEC = 7 * 3600;
const int DAYLIGHT_OFFSET_SEC = 0;

// ================= LCD =================
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ================= FIREBASE =================
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ================= SENSOR =================
DHT dht(DHTPIN, DHTTYPE);

// ================= VARIABLE =================
unsigned long lastSend = 0;
bool pumpState = false;

String mode = "manual";
bool pumpManual = false;
int moistureLimit = 60;
float temperatureMin = 24.0;
float temperatureMax = 32.0;
int scheduleStartHour = 0;
int scheduleStartMinute = 0;
int scheduleEndHour = 0;
int scheduleEndMinute = 0;

bool wateringSessionActive = false;
String wateringMode = "";
String wateringReason = "";
int wateringStartMoisture = 0;
float wateringStartTemperature = NAN;
unsigned long wateringStartMillis = 0;
long long wateringStartTimestamp = 0;

// ================= BASE PATH =================
String basePath() {
  String path = "/devices/";
  path += DEVICE_ID;
  return path;
}

// ================= HELPER =================
void serialLog(const String& message) {
  Serial.print("[SMART-AGRI] ");
  Serial.println(message);
}

String safeTemperatureText(float temp) {
  if (isnan(temp)) {
    return "nan";
  }
  return String(temp, 1);
}

String buildTimeSyncMessage(const tm& timeInfo) {
  String message = "Waktu tersinkron: ";
  message += String(timeInfo.tm_mday);
  message += "/";
  message += String(timeInfo.tm_mon + 1);
  message += " ";
  message += String(timeInfo.tm_hour);
  message += ":";
  message += String(timeInfo.tm_min);
  return message;
}

String joinPath(const String& base, const char* suffix) {
  String fullPath = base;
  fullPath += suffix;
  return fullPath;
}

long long currentTimestampMs() {
  time_t now = time(nullptr);
  if (now <= 100000) {
    return 0;
  }
  return static_cast<long long>(now) * 1000LL;
}

void syncTime() {
  configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, "pool.ntp.org", "time.nist.gov");
  serialLog("Sinkronisasi waktu NTP dimulai");

  struct tm timeInfo;
  for (int retry = 0; retry < 15; retry++) {
    if (getLocalTime(&timeInfo, 500)) {
      serialLog(buildTimeSyncMessage(timeInfo));
      return;
    }
    delay(200);
  }

  serialLog("Waktu belum tersinkron, mode schedule menunggu NTP");
}

bool isWithinScheduleWindow() {
  struct tm timeInfo;
  if (!getLocalTime(&timeInfo, 100)) {
    return false;
  }

  const int nowMinute = (timeInfo.tm_hour * 60) + timeInfo.tm_min;
  const int startMinute = (scheduleStartHour * 60) + scheduleStartMinute;
  const int endMinute = (scheduleEndHour * 60) + scheduleEndMinute;

  if (startMinute == endMinute) {
    return false;
  }

  if (startMinute < endMinute) {
    return nowMinute >= startMinute && nowMinute < endMinute;
  }

  return nowMinute >= startMinute || nowMinute < endMinute;
}

void beginWateringSession(const String& activeMode, const String& reason, int soil, float temp) {
  wateringSessionActive = true;
  wateringMode = activeMode;
  wateringReason = reason;
  wateringStartMoisture = soil;
  wateringStartTemperature = temp;
  wateringStartMillis = millis();
  wateringStartTimestamp = currentTimestampMs();

  String message = "Penyiraman mulai | mode=";
  message += activeMode;
  message += " | reason=";
  message += reason;
  message += " | moisture=";
  message += String(soil);
  message += " | temp=";
  message += safeTemperatureText(temp);
  serialLog(message);
}

void saveWateringHistory(int soil, float temp) {
  if (!wateringSessionActive) {
    return;
  }

  FirebaseJson json;
  json.set("timestamp", wateringStartTimestamp > 0 ? wateringStartTimestamp : currentTimestampMs());
  json.set("type", wateringMode);
  json.set("endedAt", currentTimestampMs());
  json.set("durationMs", static_cast<int>(millis() - wateringStartMillis));
  json.set("startMoisture", wateringStartMoisture);
  json.set("endMoisture", soil);
  json.set("startTemperature", wateringStartTemperature);
  json.set("endTemperature", temp);
  json.set("reason", wateringReason);

  String historyPath = basePath();
  historyPath += "/history";

  bool success = Firebase.RTDB.pushJSON(&fbdo, historyPath.c_str(), &json);
  if (success) {
    serialLog("Histori penyiraman berhasil disimpan ke database");
  } else {
    String message = "Gagal simpan histori: ";
    message += fbdo.errorReason();
    serialLog(message);
  }

  wateringSessionActive = false;
  wateringMode = "";
  wateringReason = "";
  wateringStartMoisture = 0;
  wateringStartTemperature = NAN;
  wateringStartMillis = 0;
  wateringStartTimestamp = 0;
}

// ================= WIFI =================
void connectWiFi() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  lcd.clear();
  lcd.print("Connecting WiFi");
  serialLog("Menghubungkan ke WiFi...");

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    lcd.clear();
    lcd.print("WiFi Connected");
    String message = "WiFi connected, IP: ";
    message += WiFi.localIP().toString();
    serialLog(message);
    syncTime();
    delay(1500);
  } else {
    lcd.clear();
    lcd.print("WiFi Failed!");
    serialLog("WiFi gagal, restart ESP32");
    delay(2000);
    ESP.restart();
  }
}

// ================= SENSOR =================
int readSoilRaw() {
  return analogRead(SOIL_PIN);
}

int readSoilPercent(int raw) {
  int percent = map(raw, 1400, 3200, 100, 0);
  return constrain(percent, 0, 100);
}

// ================= SETUP =================
void setup() {
  Serial.begin(115200);
  delay(500);
  serialLog("Booting Smart Agriculture");

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW); // OFF

  analogReadResolution(12);
  dht.begin();

  Wire.begin(21, 22);
  lcd.init();
  lcd.backlight();

  lcd.print("Smart Agriculture");
  delay(2000);

  connectWiFi();

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  serialLog("Inisialisasi Firebase selesai");

  lcd.clear();
  lcd.print("Firebase Ready");
  delay(1500);
}

// ================= LOOP =================
void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  if (!Firebase.ready()) {
    serialLog("Firebase belum siap");
    delay(500);
    return;
  }

  String path = basePath();

  // ===== PATH =====
  String pathMode = joinPath(path, "/control_status/mode");
  String pathPump = joinPath(path, "/control_status/pump");
  String pathAutoMoisture = joinPath(path, "/control_status/auto_config/moistureDryBelow");
  String pathAutoTempMin = joinPath(path, "/control_status/auto_config/temperatureMin");
  String pathAutoTempMax = joinPath(path, "/control_status/auto_config/temperatureMax");
  String pathScheduleStartHour = joinPath(path, "/control_status/schedule/startHour");
  String pathScheduleStartMinute = joinPath(path, "/control_status/schedule/startMinute");
  String pathScheduleEndHour = joinPath(path, "/control_status/schedule/endHour");
  String pathScheduleEndMinute = joinPath(path, "/control_status/schedule/endMinute");
  String pathSensor = joinPath(path, "/sensor_data");
  String pathLastSeen = joinPath(path, "/last_seen");

  // ===== GET DATA =====
  if (Firebase.RTDB.getString(&fbdo, pathMode.c_str())) {
    mode = fbdo.stringData();
    mode.toLowerCase();
  }

  if (Firebase.RTDB.getBool(&fbdo, pathPump.c_str())) {
    pumpManual = fbdo.boolData();
  }

  if (Firebase.RTDB.getInt(&fbdo, pathAutoMoisture.c_str())) {
    moistureLimit = fbdo.intData();
  }

  if (Firebase.RTDB.getFloat(&fbdo, pathAutoTempMin.c_str())) {
    temperatureMin = fbdo.floatData();
  }

  if (Firebase.RTDB.getFloat(&fbdo, pathAutoTempMax.c_str())) {
    temperatureMax = fbdo.floatData();
  }

  if (Firebase.RTDB.getInt(&fbdo, pathScheduleStartHour.c_str())) {
    scheduleStartHour = fbdo.intData();
  }

  if (Firebase.RTDB.getInt(&fbdo, pathScheduleStartMinute.c_str())) {
    scheduleStartMinute = fbdo.intData();
  }

  if (Firebase.RTDB.getInt(&fbdo, pathScheduleEndHour.c_str())) {
    scheduleEndHour = fbdo.intData();
  }

  if (Firebase.RTDB.getInt(&fbdo, pathScheduleEndMinute.c_str())) {
    scheduleEndMinute = fbdo.intData();
  }

  // ===== SENSOR =====
  const int rawSoil = readSoilRaw();
  const int soil = readSoilPercent(rawSoil);
  const float temp = dht.readTemperature();

  // ===== LOGIC =====
  bool shouldPump = false;
  String wateringReasonCandidate = "idle";

  if (mode == "manual") {
    shouldPump = pumpManual;
    wateringReasonCandidate = pumpManual ? "manual_toggle" : "manual_off";
  } else if (mode == "auto") {
    const bool isTemperatureValid = !isnan(temp);
    const bool isSoilDry = soil < moistureLimit;
    const bool isTemperatureIdeal =
      isTemperatureValid &&
      temp >= temperatureMin &&
      temp <= temperatureMax;

    shouldPump = isSoilDry && isTemperatureIdeal;
    wateringReasonCandidate = shouldPump ? "auto_sensor_trigger" : "auto_waiting";
  } else if (mode == "schedule") {
    const bool scheduleActive = isWithinScheduleWindow();
    shouldPump = scheduleActive;
    wateringReasonCandidate = scheduleActive ? "schedule_window_active" : "schedule_waiting";
  } else {
    mode = "manual";
    shouldPump = pumpManual;
    wateringReasonCandidate = pumpManual ? "manual_toggle" : "manual_off";
  }

  // ===== APPLY =====
  if (shouldPump != pumpState) {
    if (shouldPump) {
      beginWateringSession(mode, wateringReasonCandidate, soil, temp);
    } else {
      saveWateringHistory(soil, temp);
    }

    pumpState = shouldPump;
    digitalWrite(RELAY_PIN, pumpState ? HIGH : LOW);

    Firebase.RTDB.setBool(&fbdo, pathPump.c_str(), pumpState);
    String pumpMessage = "Pompa ";
    pumpMessage += (pumpState ? "MENYALA" : "MATI");
    serialLog(pumpMessage);
  }

  // ===== SEND DATA =====
  if (millis() - lastSend > 3000) {
    lastSend = millis();

    FirebaseJson json;
    json.set("temperature", temp);
    json.set("moisture", soil);
    json.set("rawMoisture", rawSoil);

    Firebase.RTDB.setJSON(&fbdo, pathSensor.c_str(), &json);
    Firebase.RTDB.setTimestamp(&fbdo, pathLastSeen.c_str());

    String message = "Sensor | mode=";
    message += mode;
    message += " | pump=";
    message += (pumpState ? "on" : "o ff");
    message += " | temp=";
    message += safeTemperatureText(temp);
    message += "C | moisture=";
    message += String(soil);
    message += "% | raw=";
    message += String(rawSoil);
    serialLog(message);
  }

  // ===== LCD =====
  lcd.clear();

  lcd.setCursor(0, 0);
  lcd.print("T:");
  if (isnan(temp)) {
    lcd.print("--");
  } else {
    lcd.print((int) temp);
  }
  lcd.print("C M:");
  lcd.print(soil);

  lcd.setCursor(0, 1);
  lcd.print(pumpState ? "P:ON " : "P:OFF ");
  lcd.print(mode);

  delay(1000);
}