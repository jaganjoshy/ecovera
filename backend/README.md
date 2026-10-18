# Soil Analysis Backend

This is the backend service for the Soil Analysis application. It provides machine learning-based predictions for crop recommendations and fertilizer suggestions based on soil parameters.

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
```

2. Activate the virtual environment:
- Windows:
```bash
venv\Scripts\activate
```
- Linux/Mac:
```bash
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

## Running the Server

1. Make sure you're in the backend directory
2. Run the Flask application:
```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### POST /predict

Predicts suitable crops and fertilizers based on soil parameters.

Request body:
```json
{
    "nitrogen": 90,
    "phosphorus": 42,
    "potassium": 43,
    "temperature": 20.87,
    "humidity": 82.00,
    "ph": 6.50,
    "rainfall": 202.93
}
```

Response:
```json
{
    "suitable_crop": "rice",
    "recommended_fertilizer": "NPK",
    "confidence_score": 0.95,
    "additional_notes": "Predictions based on machine learning models trained on agricultural data."
}
```

## Machine Learning Models

The application uses two Random Forest Classifier models:
1. Crop Recommendation Model: Predicts suitable crops based on soil parameters
2. Fertilizer Recommendation Model: Suggests appropriate fertilizers based on soil parameters and crop type

Models are automatically trained on first run and saved for future use. 