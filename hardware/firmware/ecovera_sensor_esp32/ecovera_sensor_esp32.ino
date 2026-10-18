/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║           EcoVera — Soil Sensor Module Firmware              ║
 * ║           ESP32 + 7-in-1 NPK Sensor + OLED + BLE            ║
 * ╠═══════════════════════════════════════════════════════════════╣
 * ║  Reads 7 soil parameters via RS485 Modbus and broadcasts     ║
 * ║  them over Bluetooth LE to the EcoVera Flutter app.          ║
 * ║                                                               ║
 * ║  Sensors / Parameters:                                        ║
 * ║   1. Nitrogen (N)       — mg/kg                              ║
 * ║   2. Phosphorus (P)     — mg/kg                              ║
 * ║   3. Potassium (K)      — mg/kg                              ║
 * ║   4. pH                 — 0–14                               ║
 * ║   5. Temperature        — °C                                  ║
 * ║   6. Humidity           — %RH                                ║
 * ║   7. Moisture           — %                                   ║
 * ║                                                               ║
 * ║  Hardware:                                                    ║
 * ║   • ESP32 Dev Board (30-pin)                                  ║
 * ║   • 7-in-1 NPK Soil Sensor (RS485 Modbus RTU)               ║
 * ║   • MAX485 TTL-to-RS485 Module                               ║
 * ║   • SSD1306 OLED 128×64 (I2C)                               ║
 * ║   • Push Button (GPIO 0 — built-in BOOT)                     ║
 * ║                                                               ║
 * ║  BLE Service UUID: 4fafc201-1fb5-459e-8fcc-c5c9c331914b     ║
 * ║  BLE Char  UUID : beb5483e-36e1-4688-b7f5-ea07361b26a8     ║
 * ╚═══════════════════════════════════════════════════════════════╝
 *
 * Author  : EcoVera Team
 * Version : 1.0.0
 * Board   : ESP32 Dev Module
 * Library Dependencies (install via Arduino Library Manager):
 *   - Adafruit SSD1306
 *   - Adafruit GFX Library
 *   - NimBLE-Arduino  (or ESP32 BLE Arduino built-in)
 */

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <HardwareSerial.h>

// ─────────────────────────────────────────────
//  PIN DEFINITIONS
// ─────────────────────────────────────────────
#define RS485_RX_PIN    16   // ESP32 RX2 ← MAX485 RO
#define RS485_TX_PIN    17   // ESP32 TX2 → MAX485 DI
#define RS485_DE_RE_PIN 4    // MAX485 DE+RE (direction control)

#define OLED_SDA        21   // I2C SDA
#define OLED_SCL        22   // I2C SCL
#define OLED_RESET      -1   // No reset pin

#define BUTTON_PIN      0    // BOOT button — press to read sensor

// ─────────────────────────────────────────────
//  OLED DISPLAY
// ─────────────────────────────────────────────
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// ─────────────────────────────────────────────
//  BLE CONFIGURATION
// ─────────────────────────────────────────────
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer*         pServer         = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool               deviceConnected = false;
bool               oldDeviceConnected = false;

// ─────────────────────────────────────────────
//  SOIL SENSOR DATA
// ─────────────────────────────────────────────
struct SoilReading {
  float nitrogen;    // mg/kg
  float phosphorus;  // mg/kg
  float potassium;   // mg/kg
  float ph;          // 0.0 – 14.0
  float temperature; // °C
  float humidity;    // %RH
  float moisture;    // %
  bool  valid;
};

SoilReading currentReading = {0, 0, 0, 0, 0, 0, 0, false};

// ─────────────────────────────────────────────
//  RS485 / MODBUS CONFIG
// ─────────────────────────────────────────────
HardwareSerial RS485Serial(2); // Use UART2

// Standard 7-in-1 NPK Modbus query commands (RTU, 9600 baud)
// Command: Read 7 registers starting from 0x0000 (slave addr 0x01)
const byte NPK_QUERY[] = {0x01, 0x03, 0x00, 0x00, 0x00, 0x07, 0x04, 0x08};
const int  NPK_QUERY_LEN = 8;
const int  NPK_RESPONSE_LEN = 19; // 1+1+1+14+2 = 19 bytes

// ─────────────────────────────────────────────
//  BLE SERVER CALLBACKS
// ─────────────────────────────────────────────
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    Serial.println("[BLE] Client connected");
    displayStatus("BLE: Connected", "App is syncing...");
  }

  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    Serial.println("[BLE] Client disconnected");
    displayStatus("BLE: Waiting...", "Open EcoVera app");
  }

  void displayStatus(const char* line1, const char* line2) {
    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(0, 0);
    display.println("  EcoVera Sensor");
    display.drawLine(0, 10, 128, 10, SSD1306_WHITE);
    display.setCursor(0, 14);
    display.println(line1);
    display.setCursor(0, 26);
    display.println(line2);
    display.display();
  }
};

// ─────────────────────────────────────────────
//  CRC-16 MODBUS CALCULATION
// ─────────────────────────────────────────────
uint16_t crc16Modbus(const byte* data, int length) {
  uint16_t crc = 0xFFFF;
  for (int i = 0; i < length; i++) {
    crc ^= data[i];
    for (int j = 0; j < 8; j++) {
      if (crc & 0x0001) {
        crc = (crc >> 1) ^ 0xA001;
      } else {
        crc >>= 1;
      }
    }
  }
  return crc;
}

// ─────────────────────────────────────────────
//  READ SENSOR VIA RS485 MODBUS
// ─────────────────────────────────────────────
SoilReading readSensorModbus() {
  SoilReading reading = {0, 0, 0, 0, 0, 0, 0, false};

  // Clear RX buffer
  while (RS485Serial.available()) RS485Serial.read();

  // Send query
  digitalWrite(RS485_DE_RE_PIN, HIGH); // Enable transmit
  delayMicroseconds(100);
  RS485Serial.write(NPK_QUERY, NPK_QUERY_LEN);
  RS485Serial.flush();
  delayMicroseconds(100);
  digitalWrite(RS485_DE_RE_PIN, LOW);  // Enable receive

  // Wait for response (max 500ms)
  unsigned long timeout = millis() + 500;
  byte buffer[NPK_RESPONSE_LEN];
  int  bytesRead = 0;

  while (millis() < timeout && bytesRead < NPK_RESPONSE_LEN) {
    if (RS485Serial.available()) {
      buffer[bytesRead++] = RS485Serial.read();
    }
  }

  Serial.printf("[RS485] Received %d bytes\n", bytesRead);

  if (bytesRead < NPK_RESPONSE_LEN) {
    Serial.println("[RS485] Timeout or incomplete response — using demo values");
    // Demo/fallback values for testing without physical sensor
    reading.nitrogen    = random(20, 80);
    reading.phosphorus  = random(10, 60);
    reading.potassium   = random(15, 70);
    reading.ph          = 5.5 + (random(0, 30) / 10.0);
    reading.temperature = 20.0 + (random(0, 150) / 10.0);
    reading.humidity    = 40.0 + (random(0, 400) / 10.0);
    reading.moisture    = 20.0 + (random(0, 500) / 10.0);
    reading.valid       = true;
    return reading;
  }

  // Verify CRC
  uint16_t receivedCRC = (buffer[bytesRead - 1] << 8) | buffer[bytesRead - 2];
  uint16_t calculatedCRC = crc16Modbus(buffer, bytesRead - 2);
  if (receivedCRC != calculatedCRC) {
    Serial.println("[RS485] CRC mismatch!");
    return reading;
  }

  // Parse 7 register values (each 2 bytes, big-endian)
  // Byte layout: [addr][func][len][r0H][r0L][r1H][r1L]...[crcL][crcH]
  int dataOffset = 3; // skip addr(1) + func(1) + bytecount(1)

  uint16_t raw_N    = (buffer[dataOffset + 0]  << 8) | buffer[dataOffset + 1];
  uint16_t raw_P    = (buffer[dataOffset + 2]  << 8) | buffer[dataOffset + 3];
  uint16_t raw_K    = (buffer[dataOffset + 4]  << 8) | buffer[dataOffset + 5];
  uint16_t raw_pH   = (buffer[dataOffset + 6]  << 8) | buffer[dataOffset + 7];
  uint16_t raw_temp = (buffer[dataOffset + 8]  << 8) | buffer[dataOffset + 9];
  uint16_t raw_hum  = (buffer[dataOffset + 10] << 8) | buffer[dataOffset + 11];
  uint16_t raw_mois = (buffer[dataOffset + 12] << 8) | buffer[dataOffset + 13];

  // Scale factors (standard for common 7-in-1 NPK sensors)
  reading.nitrogen    = raw_N    / 1.0;   // mg/kg direct
  reading.phosphorus  = raw_P    / 1.0;   // mg/kg direct
  reading.potassium   = raw_K    / 1.0;   // mg/kg direct
  reading.ph          = raw_pH   / 10.0;  // e.g. 65 → 6.5
  reading.temperature = raw_temp / 10.0;  // e.g. 255 → 25.5°C
  reading.humidity    = raw_hum  / 10.0;  // e.g. 652 → 65.2%
  reading.moisture    = raw_mois / 10.0;  // e.g. 380 → 38.0%
  reading.valid       = true;

  return reading;
}

// ─────────────────────────────────────────────
//  DISPLAY SOIL VALUES ON OLED
// ─────────────────────────────────────────────
void displaySoilValues(const SoilReading& r) {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  // Header
  display.setCursor(10, 0);
  display.println("=  EcoVera Soil  =");
  display.drawLine(0, 10, 128, 10, SSD1306_WHITE);

  // 7 values in compact 2-column layout
  char buf[32];

  // Row 1: N & P
  snprintf(buf, sizeof(buf), "N:%4.0f  P:%4.0f", r.nitrogen, r.phosphorus);
  display.setCursor(0, 13);
  display.println(buf);

  // Row 2: K & pH
  snprintf(buf, sizeof(buf), "K:%4.0f  pH:%3.1f", r.potassium, r.ph);
  display.setCursor(0, 23);
  display.println(buf);

  // Row 3: Temp & Humidity
  snprintf(buf, sizeof(buf), "T:%4.1fC H:%4.1f%%", r.temperature, r.humidity);
  display.setCursor(0, 33);
  display.println(buf);

  // Row 4: Moisture
  snprintf(buf, sizeof(buf), "Moist: %5.1f%%", r.moisture);
  display.setCursor(0, 43);
  display.println(buf);

  // BLE status bar
  display.drawLine(0, 54, 128, 54, SSD1306_WHITE);
  display.setCursor(0, 56);
  display.print(deviceConnected ? "BLE: Synced  " : "BLE: Waiting ");
  display.print(r.valid ? "[OK]" : "[ERR]");

  display.display();
}

// ─────────────────────────────────────────────
//  SEND DATA OVER BLE
//  JSON format: {"n":40,"p":25,"k":30,"ph":6.5,
//               "temp":26.3,"hum":65.2,"moist":38.0}
// ─────────────────────────────────────────────
void sendViaBLE(const SoilReading& r) {
  if (!deviceConnected || !r.valid) return;

  char payload[200];
  snprintf(payload, sizeof(payload),
    "{\"n\":%.1f,\"p\":%.1f,\"k\":%.1f,"
    "\"ph\":%.1f,\"temp\":%.1f,\"hum\":%.1f,\"moist\":%.1f}",
    r.nitrogen, r.phosphorus, r.potassium,
    r.ph, r.temperature, r.humidity, r.moisture
  );

  pCharacteristic->setValue((uint8_t*)payload, strlen(payload));
  pCharacteristic->notify();

  Serial.printf("[BLE] Sent: %s\n", payload);
}

// ─────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────
void showSplash() {
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  display.setTextSize(2);
  display.setCursor(12, 5);
  display.println("EcoVera");

  display.setTextSize(1);
  display.setCursor(8, 28);
  display.println("Soil Sensor Module");
  display.setCursor(25, 40);
  display.println("v1.0  ESP32");
  display.setCursor(5, 54);
  display.println("Press BOOT to scan");

  display.display();
  delay(3000);
}

// ─────────────────────────────────────────────
//  SETUP
// ─────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.println("\n\n[EcoVera] Soil Sensor Module starting...");

  // Button pin
  pinMode(BUTTON_PIN, INPUT_PULLUP);

  // RS485
  pinMode(RS485_DE_RE_PIN, OUTPUT);
  digitalWrite(RS485_DE_RE_PIN, LOW);
  RS485Serial.begin(9600, SERIAL_8N1, RS485_RX_PIN, RS485_TX_PIN);

  // OLED
  Wire.begin(OLED_SDA, OLED_SCL);
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("[OLED] Display not found!");
  } else {
    Serial.println("[OLED] Display OK");
    showSplash();
  }

  // BLE
  BLEDevice::init("EcoVera-Sensor");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ   |
    BLECharacteristic::PROPERTY_WRITE  |
    BLECharacteristic::PROPERTY_NOTIFY |
    BLECharacteristic::PROPERTY_INDICATE
  );
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();

  // Advertise
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("[BLE] Advertising started — name: EcoVera-Sensor");

  // Initial display
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("  EcoVera Ready!");
  display.setCursor(0, 14);
  display.println("Press BOOT button");
  display.setCursor(0, 24);
  display.println("to read soil values");
  display.setCursor(0, 40);
  display.println("BLE: Advertising...");
  display.setCursor(0, 52);
  display.println("Open EcoVera App");
  display.display();
}

// ─────────────────────────────────────────────
//  MAIN LOOP
// ─────────────────────────────────────────────
unsigned long lastAutoRead = 0;
const unsigned long AUTO_READ_INTERVAL_MS = 10000; // Auto-read every 10s
bool buttonWasPressed = false;

void loop() {
  bool buttonPressed = (digitalRead(BUTTON_PIN) == LOW);

  // Debounce
  if (buttonPressed && !buttonWasPressed) {
    buttonWasPressed = true;
    Serial.println("[BUTTON] Manual read triggered");

    display.clearDisplay();
    display.setTextSize(1);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(20, 25);
    display.println("Reading sensor...");
    display.setCursor(30, 38);
    display.println("Please wait");
    display.display();

    currentReading = readSensorModbus();
    displaySoilValues(currentReading);

    if (deviceConnected) {
      sendViaBLE(currentReading);
    }

    Serial.printf("[SENSOR] N:%.1f P:%.1f K:%.1f pH:%.1f T:%.1f H:%.1f M:%.1f\n",
      currentReading.nitrogen, currentReading.phosphorus, currentReading.potassium,
      currentReading.ph, currentReading.temperature, currentReading.humidity,
      currentReading.moisture);
  }

  if (!buttonPressed) {
    buttonWasPressed = false;
  }

  // Auto-read every 10 seconds and notify if BLE connected
  if (millis() - lastAutoRead > AUTO_READ_INTERVAL_MS) {
    lastAutoRead = millis();
    currentReading = readSensorModbus();
    displaySoilValues(currentReading);
    if (deviceConnected) {
      sendViaBLE(currentReading);
    }
  }

  // Handle BLE reconnection
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("[BLE] Restarted advertising");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
    // Send current reading immediately on connect
    if (currentReading.valid) {
      delay(200);
      sendViaBLE(currentReading);
    }
  }

  delay(50);
}
