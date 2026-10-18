<div align="center">

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
<img src="https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white" />

# 🌱 EcoVera — Soil Nutrition Analyzer

**An AI-powered smart soil analysis app that recommends the best crops and fertilizers based on your soil's unique parameters.**

*Mini Project · 2025 · Flutter + Flask + Firebase*

</div>

---

## ✨ What EcoVera Does

EcoVera bridges the gap between modern agriculture and machine learning. Input your soil parameters and instantly get personalized, AI-driven crop and fertilizer recommendations — helping farmers make smarter, data-backed decisions.

| Input Parameters | AI Outputs |
|---|---|
| Nitrogen (N), Phosphorus (P), Potassium (K) | 🌾 Best crop recommendations |
| pH, Temperature, Humidity | 🌿 Organic fertilizer suggestions |
| Rainfall, Moisture | 📊 Confidence score & farming tips |

---

## 🏗️ Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
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
- Firebase project configured

### 1. Clone the Repository
```bash
git clone https://github.com/jaganjoshy/ecovera.git
cd ecovera
```

### 2. Start the Backend (Flask)
```bash
cd backend
pip install -r requirements.txt
python app.py
```
> Backend runs at `http://localhost:5000`

### 3. Configure the App
Edit [`lib/config.dart`](lib/config.dart) and set your backend URL:
```dart
static const String apiBaseUrl = 'http://localhost:5000';
// For a physical device, use your machine's local IP:
// static const String apiBaseUrl = 'http://192.168.x.x:5000';
```

### 4. Run the Flutter App
```bash
flutter pub get
flutter run
```

---

## 📁 Project Structure

```
ecovera/
├── 📱 lib/                    # Flutter app source
│   ├── screens/               # UI screens (home, login, analysis, results)
│   ├── service/               # AI & soil API service layer
│   ├── services/              # Auth & additional services
│   ├── widgets/               # Reusable UI components
│   ├── model/                 # Data models
│   ├── config/                # App configuration
│   └── config.dart            # API base URL & app constants
│
├── 🐍 backend/                # Flask REST API
│   ├── app.py                 # Main server + ML inference routes
│   ├── requirements.txt       # Python dependencies
│   ├── data/                  # Training datasets (CSV)
│   └── models/                # Trained ML model artifacts
│
├── 🌐 web/                    # Flutter Web build target
├── 📱 android/                # Android platform files
├── 🍎 ios/                    # iOS platform files
└── 🖥️  windows/               # Windows desktop target
```

---

## 🌟 Features

- 🌾 **Smart Crop Recommendations** — AI selects the most suitable crop for your soil
- 🌿 **Organic Fertilizer Advice** — Eco-friendly, data-backed recommendations
- 📊 **Confidence Scoring** — Know how sure the model is
- 🔐 **Secure Auth** — Google Sign-In & Email/Password via Firebase
- 🌍 **Cross-Platform** — Works on Android, iOS, and Web
- ⚡ **Fast Inference** — Lightweight scikit-learn model with rule-based fallback

---

## 📸 Screenshots

> *Run the app and explore the beautiful soil analysis interface!*

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 👨‍💻 Author

**Jagan Joshy**
- GitHub: [@jaganjoshy](https://github.com/jaganjoshy)

---

## 📄 License

This project is developed for educational purposes as part of a college mini project (2025).

---

<div align="center">
<i>Made with ❤️ using Flutter & Python</i>
</div>
