<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
<img src="https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/ESP32-E7352C?style=for-the-badge&logo=espressif&logoColor=white" />
<img src="https://img.shields.io/badge/Bluetooth-0082FC?style=for-the-badge&logo=bluetooth&logoColor=white" />
<img src="https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white" />

# 🌱 EcoVera — Soil Nutrition Analyzer

**An AI-powered smart soil analysis system that reads real sensor data from an NPK hardware module,  
syncs it wirelessly to the app, and predicts the best crops & fertilizers using machine learning.**

*Mini Project · 2025 · Flutter + Flask + Firebase + ESP32 BLE*

</div>

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│               EcoVera — End-to-End Data Flow                    │
│                                                                  │
│  ┌──────────────────┐   RS485   ┌────────────┐                  │
│  │  7-in-1 NPK      │ ────────→ │   ESP32    │  OLED Display    │
│  │  Soil Sensor     │  Modbus   │  Dev Board │ ───────────────→ │
│  │  (N,P,K,pH,      │           │            │                  │
│  │  Temp,Hum,Moist) │           │  Firmware  │                  │
│  └──────────────────┘           └─────┬──────┘                  │
│                                       │                          │
│                                  BLE Notify                      │
│                                  (JSON payload)                  │
│                                       │                          │
│                               ┌───────▼────────┐                │
│                               │  Flutter App   │                │
│                               │  (EcoVera)     │                │
│                               │  Sensor Sync   │                │
│                               │  Screen        │                │
│                               └───────┬────────┘                │
│                                       │                          │
│                               HTTP POST /analyze                 │
│                                       │                          │
│                               ┌───────▼────────┐                │
│                               │  Python Flask  │                │
│                               │  + scikit-learn│                │
│                               │  ML Backend    │                │
│                               └───────┬────────┘                │
│                                       │                          │
│                         Crop + Fertilizer Predictions            │
│                         + Confidence Score                       │
│                                       │                          │
│                               ┌───────▼────────┐                │
│                               │  Results Screen│                │
│                               │  (Flutter)     │                │
│                               └────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

---

## ✨ Features

| Feature | Description |
|---|---|
| 📡 **NPK Sensor Module** | ESP32 + 7-in-1 RS485 sensor reads N, P, K, pH, Temp, Humidity, Moisture |
| 📟 **OLED Display** | All 7 values displayed live on 128×64 OLED screen |
| 🔵 **BLE Sync** | Wireless Bluetooth LE sync to Flutter app — one tap, zero typing |
| 🌾 **AI Crop Prediction** | scikit-learn model recommends best crops for your soil |
| 🌿 **Bio Fertilizer Advice** | Organic fertilizer recommendations with ECO badge |
| 📊 **Confidence Score** | Know how sure the model is |
| 🔐 **Firebase Auth** | Google Sign-In & Email/Password |
| 🌍 **Cross-Platform** | Android, iOS, Web, Windows |

---

## 🔧 Hardware Module

| Component | Spec |
|---|---|
| Microcontroller | ESP32 Dev Board (30-pin) |
| Soil Sensor | 7-in-1 NPK (RS485 Modbus RTU) |
| Communication | MAX485 TTL↔RS485 Module |
| Display | SSD1306 OLED 128×64 (I2C) |
| Wireless | Bluetooth LE (built-in ESP32) |
| Button | BOOT pin (GPIO0) for manual read |

### OLED Display Output
```
┌──────────────────────────────┐
│   =  EcoVera Soil  =         │
│──────────────────────────────│
│ N:  45  P:  28               │
│ K:  62  pH: 6.5              │
│ T: 26.3C H: 65.2%            │
│ Moist:  38.0%                │
│──────────────────────────────│
│ BLE: Synced          [OK]    │
└──────────────────────────────┘
```

### BLE Configuration
| Property | Value |
|---|---|
| BLE Device Name | `EcoVera-Sensor` |
| Service UUID | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| Characteristic UUID | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |
| Data Format | JSON `{"n":45,"p":28,"k":62,"ph":6.5,"temp":26.3,"hum":65.2,"moist":38.0}` |

> **Demo Mode**: If the physical sensor is not connected, the ESP32 automatically generates realistic random values — perfect for testing the full app flow.

---

## 🏗️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| 📡 **Firmware** | ESP32 (Arduino C++) | Sensor reading + OLED + BLE |
| 📱 **Frontend** | Flutter (Dart) | Cross-platform mobile & web UI |
| 🐍 **Backend** | Python + Flask | REST API & ML inference |
| 🔐 **Auth** | Firebase Authentication | Google Sign-In + Email/Password |
| 🤖 **ML** | scikit-learn | Crop recommendation model |
| 🗄️ **Database** | Firebase Firestore | User data & analysis history |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Python ≥ 3.9
- Arduino IDE ≥ 2.0 (for firmware)
- Firebase project configured

### 1. Clone the Repository
```bash
git clone https://github.com/jaganjoshy/ecovera.git
cd ecovera
```

### 2. Flash the Sensor Firmware (ESP32)
```
1. Open hardware/firmware/ecovera_sensor_esp32/ecovera_sensor_esp32.ino
   in Arduino IDE

2. Install libraries via Manage Libraries:
   - Adafruit SSD1306
   - Adafruit GFX Library

3. Board: ESP32 Dev Module | 115200 baud

4. Upload → ESP32 shows splash → ready to use!
```
→ See [hardware/README.md](hardware/README.md) for full wiring diagram

### 3. Start the Backend (Flask)
```bash
cd backend
pip install -r requirements.txt
python app.py
```
> Backend runs at `http://localhost:5000`

### 4. Configure the App
Edit [`lib/config.dart`](lib/config.dart):
```dart
static const String apiBaseUrl = 'http://localhost:5000';
```

### 5. Run the Flutter App
```bash
flutter pub get
flutter run
```

---

## 📱 How to Use

```
1. Power on the ESP32 sensor module
   └─→ OLED shows "EcoVera Ready! Press BOOT to scan"

2. Open EcoVera app → Go to Analysis screen

3. Tap "Sync from NPK Sensor Module" (blue button)
   └─→ App scans for "EcoVera-Sensor" via BLE

4. Press BOOT button on ESP32
   └─→ Reads all 7 soil parameters from NPK sensor
   └─→ Displays values on OLED
   └─→ Sends JSON via BLE notify

5. App receives data → shows all 7 values → tap "Use These Values & Predict"
   └─→ Form auto-filled with sensor readings

6. Tap "Analyze Soil"
   └─→ Flask backend runs ML model
   └─→ App shows crop recommendations + fertilizer advice + confidence score
```

---

## 📁 Project Structure

```
ecovera/
│
├── 🔧 hardware/                   # ESP32 sensor module
│   ├── firmware/
│   │   └── ecovera_sensor_esp32/
│   │       └── ecovera_sensor_esp32.ino  # Arduino firmware
│   └── README.md                  # Wiring, BOM, flashing guide
│
├── 📱 lib/                        # Flutter app source
│   ├── screens/
│   │   ├── analysis_screen.dart   # Main form + Sensor Sync button
│   │   ├── sensor_sync_screen.dart # BLE scan & connect UI
│   │   ├── login_screen.dart
│   │   └── ...
│   ├── service/
│   │   └── ai_services.dart       # Local rule-based AI
│   ├── services/
│   │   ├── soil_service.dart      # Flask API client
│   │   └── auth_service.dart
│   ├── model/
│   │   └── soil_data_model.dart
│   └── config.dart
│
├── 🐍 backend/                    # Flask REST API
│   ├── app.py                     # Main server + ML inference
│   ├── requirements.txt
│   └── data/                      # CSV datasets
│
├── 🌐 web/                        # Flutter Web target
├── 📱 android/                    # Android platform
├── 🍎 ios/                        # iOS platform
└── 🖥️  windows/                   # Windows desktop
```

---

## 🌟 The 7 Soil Parameters

| # | Parameter | Unit | Sensor | Range |
|---|---|---|---|---|
| 1 | **Nitrogen (N)** | mg/kg | NPK Modbus | 0–1999 |
| 2 | **Phosphorus (P)** | mg/kg | NPK Modbus | 0–1999 |
| 3 | **Potassium (K)** | mg/kg | NPK Modbus | 0–1999 |
| 4 | **pH** | — | NPK Modbus | 3.0–9.0 |
| 5 | **Temperature** | °C | NPK Modbus | -40–80 |
| 6 | **Humidity** | %RH | NPK Modbus | 0–100 |
| 7 | **Moisture** | % | NPK Modbus | 0–100 |

---

## 🤝 Contributing

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit: `git commit -m 'Add amazing feature'`
4. Push: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 👨‍💻 Author

**Jagan Joshy**  
[@jaganjoshy](https://github.com/jaganjoshy)

---

## 📄 License

Developed for educational purposes as a college mini project (2025).

---

<div align="center">
<i>Made with ❤️ — Flutter • Python • ESP32 • Firebase</i>
</div>
