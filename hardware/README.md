# 🔧 EcoVera Hardware — Sensor Module

## Overview

The EcoVera Sensor Module is an ESP32-based device that reads **7 soil parameters** from a 7-in-1 NPK Modbus sensor, displays them on an OLED screen, and wirelessly syncs them to the EcoVera Flutter app over **Bluetooth LE (BLE)**.

---

## 🧰 Bill of Materials (BOM)

| # | Component | Qty | Notes |
|---|---|---|---|
| 1 | **ESP32 Dev Board** (30-pin) | 1 | NodeMCU-32S or similar |
| 2 | **7-in-1 NPK Soil Sensor** | 1 | RS485 Modbus RTU, measures N/P/K/pH/Temp/Humidity/Moisture |
| 3 | **MAX485 TTL↔RS485 Module** | 1 | For RS485 communication |
| 4 | **SSD1306 OLED 128×64** | 1 | I2C interface, 3.3V |
| 5 | **3.3V / 5V Power Module** | 1 | Or USB power bank |
| 6 | Jumper Wires | — | Male-to-female |
| 7 | Breadboard or PCB | 1 | For prototyping |

### Recommended sensor model
> **XY-TPNPK7** / **RS485 7-in-1 Soil Sensor** (widely available on AliExpress/Amazon)  
> Operating voltage: 12–24V DC for sensor, 3.3V for ESP32  
> Output: RS485 Modbus RTU @ 9600 baud

---

## 📐 Wiring Diagram

```
                    ┌─────────────────────────┐
                    │      ESP32 Dev Board     │
                    │                          │
 7-in-1 NPK ───A──→│ GPIO16 (RX2)  GPIO17(TX2)│←──B─── MAX485
 Soil Sensor ───B──→│ MAX485 RO     MAX485 DI  │
                    │ GPIO4  ───────MAX485 DE+RE│
                    │                          │
                    │ GPIO21 (SDA) ─────────────┼── OLED SDA
                    │ GPIO22 (SCL) ─────────────┼── OLED SCL
                    │ 3.3V ─────────────────────┼── OLED VCC
                    │ GND ──────────────────────┼── OLED GND
                    │                          │
                    │ GPIO0 (BOOT) ─── Button ──┼── GND
                    └─────────────────────────┘

Power:
  • ESP32 → USB (5V from PC or power bank)
  • NPK Sensor → 12V DC adapter (required by sensor)
  • MAX485 Module → 3.3V from ESP32
  • OLED → 3.3V from ESP32
```

### Pin Summary

| ESP32 Pin | Connected To | Purpose |
|---|---|---|
| GPIO16 (RX2) | MAX485 RO | Receive RS485 data |
| GPIO17 (TX2) | MAX485 DI | Transmit RS485 data |
| GPIO4 | MAX485 DE+RE | Direction control |
| GPIO21 | OLED SDA | I2C Data |
| GPIO22 | OLED SCL | I2C Clock |
| GPIO0 | Push Button | Manual read trigger |
| 3.3V | OLED VCC, MAX485 VCC | Power |
| GND | All GND pins | Common ground |

---

## ⚡ OLED Display Layout

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

---

## 📡 BLE Protocol

The module advertises as **`EcoVera-Sensor`** and sends JSON over BLE notify:

```json
{
  "n": 45.0,
  "p": 28.0,
  "k": 62.0,
  "ph": 6.5,
  "temp": 26.3,
  "hum": 65.2,
  "moist": 38.0
}
```

| BLE Property | Value |
|---|---|
| Device Name | `EcoVera-Sensor` |
| Service UUID | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| Characteristic UUID | `beb5483e-36e1-4688-b7f5-ea07361b26a8` |
| Properties | Read, Write, Notify |

---

## 🚀 Flashing the Firmware

### Prerequisites
- Arduino IDE ≥ 2.0 or PlatformIO
- ESP32 board support installed

### Steps

1. **Install Arduino Libraries** (Sketch → Manage Libraries):
   - `Adafruit SSD1306`
   - `Adafruit GFX Library`
   - `ESP32 BLE Arduino` (built-in with ESP32 board package)

2. **Open the sketch**:
   ```
   hardware/firmware/ecovera_sensor_esp32/ecovera_sensor_esp32.ino
   ```

3. **Board settings** in Arduino IDE:
   - Board: `ESP32 Dev Module`
   - Upload Speed: `921600`
   - Flash Frequency: `80MHz`
   - Partition Scheme: `Default 4MB with spiffs`

4. **Upload** — Press and hold BOOT button on ESP32, click Upload, release BOOT

5. **Open Serial Monitor** at 115200 baud to see debug output

---

## 🔄 Operation

| Action | Result |
|---|---|
| Power on | Shows splash screen → ready state |
| Press BOOT button | Reads sensor → displays on OLED → sends via BLE |
| Auto (every 10s) | Reads sensor automatically if BLE app is connected |
| Open EcoVera App | Scans for `EcoVera-Sensor` → connects → receives data |
| Tap "Sync from Sensor" in app | Fills form with sensor values → one tap to predict |

---

## 🐛 Troubleshooting

| Issue | Fix |
|---|---|
| OLED blank | Check I2C address (0x3C or 0x3D), check SDA/SCL wiring |
| No RS485 response | Check sensor power (needs 12V), check A/B wire polarity |
| Demo values showing | RS485 not responding — module uses random demo values |
| BLE not visible in app | Restart ESP32, check BLE is enabled on phone |
| CRC mismatch | Try swapping A/B wires on RS485 bus |

---

## 📸 Demo Mode

If the physical 7-in-1 sensor is **not connected**, the firmware automatically generates **realistic random values** for testing the full app flow. This is useful for:
- Testing the Flutter app without the sensor
- Demos and presentations
- Software development

Demo mode is indicated in Serial Monitor:  
`[RS485] Timeout or incomplete response — using demo values`
