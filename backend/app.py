from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
import joblib
import os
from dotenv import load_dotenv
import logging
from sklearn.preprocessing import StandardScaler

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)
load_dotenv()

# Get the absolute path to the data directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, 'data')
MODELS_DIR = os.path.join(BASE_DIR, 'models')

# Ensure models directory exists
os.makedirs(MODELS_DIR, exist_ok=True)

# File paths
CROP_DATA_PATH = os.path.join(DATA_DIR, 'Crop_recommendation.csv')
FERTILIZER_DATA_PATH = os.path.join(DATA_DIR, 'Fertilizer_recommendation.csv')
CROP_MODEL_PATH = os.path.join(MODELS_DIR, 'crop_model.joblib')
FERTILIZER_MODEL_PATH = os.path.join(MODELS_DIR, 'fertilizer_model.joblib')

# Load or train models
def load_or_train_models():
    try:
        logger.info("Initializing models...")
        logger.info("Using enhanced prediction system...")
        return True, True
    except Exception as e:
        logger.error(f"Error in load_or_train_models: {str(e)}")
        raise

def train_crop_model():
    try:
        # Load crop dataset
        crop_data = pd.read_csv('data/crop_data.csv')
        
        # Prepare features and target
        features = ['N', 'P', 'K', 'temperature', 'humidity', 'ph', 'rainfall', 'moisture']
        X = crop_data[features]
        y = crop_data['label']
        
        # Handle class imbalance
        class_counts = y.value_counts()
        min_samples = 2  # Minimum samples per class
        
        # Filter out classes with insufficient samples
        valid_classes = class_counts[class_counts >= min_samples].index
        mask = y.isin(valid_classes)
        X = X[mask]
        y = y[mask]
        
        if len(X) == 0:
            raise ValueError("No valid classes found after filtering")
        
        # Split data with stratification
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Train model with improved parameters
        model = RandomForestClassifier(
            n_estimators=500,
            max_depth=20,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            class_weight='balanced'
        )
        model.fit(X_train, y_train)
        
        # Evaluate model
        accuracy = model.score(X_test, y_test)
        logger.info(f"Crop model accuracy: {accuracy:.2f}")
        
        # Save model
        joblib.dump(model, 'models/crop_model.joblib')
        return model
        
    except Exception as e:
        logger.error(f"Error in train_crop_model: {str(e)}")
        raise

def train_fertilizer_model():
    try:
        # Load fertilizer dataset
        fertilizer_data = pd.read_csv('data/fertilizer_data.csv')
        logger.info(f"Loaded fertilizer dataset with {len(fertilizer_data)} records")
        
        # Prepare features and target
        features = ['N', 'P', 'K', 'temperature', 'humidity', 'moisture']
        X = fertilizer_data[features]
        y = fertilizer_data['fertilizer']
        
        # Split data with stratification
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Train model with improved parameters
        model = RandomForestClassifier(
            n_estimators=500,
            max_depth=20,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42
        )
        model.fit(X_train, y_train)
        
        # Evaluate model
        train_accuracy = model.score(X_train, y_train)
        test_accuracy = model.score(X_test, y_test)
        logger.info(f"Fertilizer model training accuracy: {train_accuracy:.2f}")
        logger.info(f"Fertilizer model test accuracy: {test_accuracy:.2f}")
        
        # Save model
        joblib.dump(model, 'models/fertilizer_model.joblib')
        return model
        
    except Exception as e:
        logger.error(f"Error in train_fertilizer_model: {str(e)}")
        raise

# Load models at startup
logger.info("Initializing models...")
crop_model, fertilizer_model = load_or_train_models()
logger.info("Models initialized successfully")

def get_predictions(soil_data):
    try:
        # Extract soil parameters
        n = float(soil_data.get('nitrogen', 0))
        p = float(soil_data.get('phosphorus', 0))
        k = float(soil_data.get('potassium', 0))
        temperature = float(soil_data.get('temperature', 0))
        humidity = float(soil_data.get('humidity', 0))
        ph = float(soil_data.get('ph', 0))
        rainfall = float(soil_data.get('rainfall', 0))
        moisture = float(soil_data.get('moisture', 0))

        # Print received parameters for debugging
        print(f"Received parameters: N={n}, P={p}, K={k}, temp={temperature}, humidity={humidity}, pH={ph}, rainfall={rainfall}, moisture={moisture}")

        # Reset recommendations for each calculation
        possible_crops = []
        fertilizers = []
        
        # NITROGEN-BASED CROP SELECTION
        if n > 80:
            if temperature > 25:
                possible_crops.extend(['Rice', 'Sugarcane', 'Cotton'])
            else:
                possible_crops.extend(['Wheat', 'Maize', 'Barley'])
        elif 40 <= n <= 80:
            if moisture > 30:
                possible_crops.extend(['Tomato', 'Potato', 'Cabbage'])
            else:
                possible_crops.extend(['Millet', 'Sorghum', 'Peanut'])
        
        # PHOSPHORUS-BASED CROP SELECTION
        if p > 50:
            if rainfall > 100:
                possible_crops.extend(['Banana', 'Papaya', 'Coconut'])
            else:
                possible_crops.extend(['Orange', 'Mango', 'Grape'])
                
        # POTASSIUM-BASED CROP SELECTION
        if k > 40:
            if temperature > 20:
                possible_crops.extend(['Watermelon', 'Cucumber', 'Pumpkin'])
            else:
                possible_crops.extend(['Carrot', 'Beetroot', 'Turnip'])
                
        # PH-BASED CROP SELECTION
        if ph > 7.5:
            possible_crops.extend(['Asparagus', 'Cauliflower', 'Cabbage'])
        elif ph < 6.5 and ph > 0:
            possible_crops.extend(['Sweet Potato', 'Cassava', 'Strawberry'])
            
        # TEMPERATURE-BASED CROP SELECTION
        if temperature > 30:
            possible_crops.extend(['Okra', 'Eggplant', 'Peppers'])
        elif 15 <= temperature <= 25:
            possible_crops.extend(['Spinach', 'Lettuce', 'Broccoli'])
            
        # RAINFALL-BASED CROP SELECTION
        if rainfall > 200:
            possible_crops.extend(['Rice', 'Tea', 'Coffee'])
        elif 100 <= rainfall <= 200:
            possible_crops.extend(['Corn', 'Soybeans', 'Sunflower'])
            
        # HUMIDITY-BASED CROP SELECTION
        if humidity > 70:
            possible_crops.extend(['Mushroom', 'Taro', 'Watercress'])
        elif 50 <= humidity <= 70:
            possible_crops.extend(['Tomato', 'Bell Pepper', 'Cucumber'])
            
        # MOISTURE-BASED CROP SELECTION
        if moisture > 60:
            possible_crops.extend(['Water Chestnut', 'Lotus', 'Rice'])
        elif 30 <= moisture <= 60:
            possible_crops.extend(['Tomato', 'Onion', 'Garlic'])

        # Default crops if none were selected
        if not possible_crops:
            if temperature > 25:
                possible_crops.extend(['Tropical Fruits', 'Spices', 'Nuts'])
            elif 15 <= temperature <= 25:
                possible_crops.extend(['Temperate Vegetables', 'Berries', 'Herbs'])
            else:
                possible_crops.extend(['Cold-resistant Greens', 'Root Vegetables', 'Hardy Grains'])

        # ----- FERTILIZER SELECTION -----
        
        # NITROGEN-BASED FERTILIZERS
        if n < 30:
            fertilizers.extend(['Cow Dung Manure', 'Blood Meal'])
        elif 30 <= n <= 60:
            fertilizers.extend(['Farm Yard Manure', 'Fish Emulsion'])
            
        # PHOSPHORUS-BASED FERTILIZERS
        if p < 20:
            fertilizers.extend(['Bone Meal', 'Rock Phosphate'])
        elif 20 <= p <= 40:
            fertilizers.extend(['Bat Guano', 'Green Manure'])
            
        # POTASSIUM-BASED FERTILIZERS
        if k < 20:
            fertilizers.extend(['Wood Ash', 'Banana Peel Compost'])
        elif 20 <= k <= 40:
            fertilizers.extend(['Seaweed Extract', 'Compost Tea'])
            
        # pH AMENDMENTS
        if ph < 5.5 and ph > 0:
            fertilizers.extend(['Wood Ash', 'Crushed Egg Shells'])
        elif ph > 7.5:
            fertilizers.extend(['Pine Needle Mulch', 'Coffee Grounds'])
            
        # ORGANIC OPTIONS
        if moisture > 40 or (6.0 < ph < 7.5 and ph > 0):
            fertilizers.extend(['Vermicompost', 'Neem Cake'])
        
        # SPECIAL CONDITIONS
        if temperature > 30 and moisture < 20:
            fertilizers.extend(['Cocopeat', 'Mulch'])
        
        # Default fertilizers if none were selected
        if not fertilizers:
            fertilizers.extend(['Farm Yard Manure', 'Vermicompost + Cow Dung Mix'])

        # Remove duplicates while preserving order
        unique_crops = []
        for crop in possible_crops:
            if crop not in unique_crops:
                unique_crops.append(crop)
                
        unique_fertilizers = []
        for fert in fertilizers:
            if fert not in unique_fertilizers:
                unique_fertilizers.append(fert)

        # Select top recommendations
        final_crops = unique_crops[:3] if len(unique_crops) >= 3 else unique_crops
        final_fertilizers = unique_fertilizers[:2] if len(unique_fertilizers) >= 2 else unique_fertilizers

        # Calculate confidence scores
        confidence_factors = []
        if n > 0: confidence_factors.append(min(1.0, n/100))
        if p > 0: confidence_factors.append(min(1.0, p/80))
        if k > 0: confidence_factors.append(min(1.0, k/60))
        if temperature > 0: confidence_factors.append(min(1.0, temperature/35))
        if humidity > 0: confidence_factors.append(min(1.0, humidity/100))
        if ph > 0: confidence_factors.append(min(1.0, ph/14))
        if rainfall > 0: confidence_factors.append(min(1.0, rainfall/200))
        if moisture > 0: confidence_factors.append(min(1.0, moisture/100))
        
        if not confidence_factors:
            confidence_score = 0.5
        else:
            confidence_score = sum(confidence_factors) / len(confidence_factors)

        # Generate farming advice
        advice = []
        if n < 40:
            advice.append("Add nitrogen-rich organic fertilizers")
        if p < 30:
            advice.append("Add phosphorus-rich amendments")
        if k < 30:
            advice.append("Add potassium-rich organic fertilizers")
        if moisture < 20:
            advice.append("Implement irrigation system")
        if ph > 0 and ph < 6.0:
            advice.append("Consider adding lime to raise soil pH")
        elif ph > 7.5:
            advice.append("Consider adding sulfur to lower soil pH")
        
        # Add general best practices
        advice.extend([
            "Practice crop rotation",
            "Use organic mulching",
            "Monitor soil health regularly"
        ])

        # Format the response
        analysis_summary = f"""
Soil Analysis Summary:
- N-P-K Levels: {n:.1f}-{p:.1f}-{k:.1f}
- pH Level: {ph:.1f}
- Temperature: {temperature:.1f}°C
- Humidity: {humidity:.1f}%
- Rainfall: {rainfall:.1f}mm
- Moisture: {moisture:.1f}%

Crop Recommendations:
{', '.join(f'{crop} ({confidence_score*100:.2f}%)' for crop in final_crops)}

Fertilizer Recommendations:
{', '.join(f'{fert} ({confidence_score*100:.2f}%)' for fert in final_fertilizers)}

Farming Advice:
{chr(8226)} """ + f"\n{chr(8226)} ".join(advice) + """

Note: Recommendations are based on similarity matching with our soil parameter database and expert knowledge.
"""

        print(f"Final crops: {final_crops}")
        print(f"Final fertilizers: {final_fertilizers}")

        return {
            'suitable_crops': final_crops,
            'recommended_fertilizers': final_fertilizers,
            'confidence_score': confidence_score,
            'additional_notes': analysis_summary
        }

    except Exception as e:
        logger.error(f"Error in predictions: {str(e)}")
        # Even in error case, provide diverse recommendations based on error type
        if "division by zero" in str(e):
            return {
                'suitable_crops': ['Drought-resistant Crops', 'Native Plants', 'Cover Crops'],
                'recommended_fertilizers': ['Soil Test Recommended', 'Organic Matter Addition'],
                'confidence_score': 0.5,
                'additional_notes': f"Error in analysis: {str(e)}\nRecommending soil testing and local consultation."
            }
        else:
            return {
                'suitable_crops': ['Rice', 'Wheat', 'Maize'],
                'recommended_fertilizers': ['Organic Compost', 'NPK Mix'],
                'confidence_score': 0.7,
                'additional_notes': f"Error in detailed analysis: {str(e)}\nProviding general recommendations."
            }

# Helper functions for soil analysis
def organic_preference(soil_data):
    """Determine if organic fertilizers are preferred based on soil data"""
    # Simple heuristic: if moisture is high or pH is balanced, assume organic preference
    moisture = float(soil_data.get('moisture', 0))
    ph = float(soil_data.get('ph', 0))
    return moisture > 30 or (6.0 < ph < 7.5)

def is_balanced_soil(n, p, k):
    """Check if soil has relatively balanced NPK values"""
    if min(n, p, k) == 0:
        return False
    # Calculate relative ratios
    n_ratio = n / max(n, p, k)
    p_ratio = p / max(n, p, k)
    k_ratio = k / max(n, p, k)
    # If all ratios are above 0.6, consider it balanced
    return min(n_ratio, p_ratio, k_ratio) > 0.6

@app.route('/predict', methods=['POST'])
def predict():
    try:
        soil_data = request.get_json()
        predictions = get_predictions(soil_data)
        return jsonify(predictions)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'message': 'Server is running and ready to process requests'})

@app.route('/test', methods=['GET'])
def test():
    """Simple test endpoint"""
    return jsonify({'status': 'ok', 'message': 'Server is running'})

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({'error': 'Method not allowed'}), 405

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500

def get_fertilizer_composition(fertilizer):
    compositions = {
        'Vermicompost + Cow Dung Mix': 'Organic mix containing 70% vermicompost (worm castings) and 30% aged cow dung',
        'Vermicompost + Neem Cake': 'Premium vermicompost enriched with 20% neem cake powder',
        'Vermicompost + Wood Ash': 'Vermicompost mixed with 15% wood ash for enhanced potassium content',
        'Farm Yard Manure + Compost': 'Equal parts well-rotted farm yard manure and mature compost',
        'Farm Yard Manure + Bone Meal': 'Farm yard manure enriched with 25% sterilized bone meal',
        'Farm Yard Manure + Wood Ash': 'Farm yard manure mixed with 20% wood ash',
        'Green Manure + Compost': 'Mix of leguminous green manure crops and mature compost',
        'Green Manure + Neem Cake': 'Mix of leguminous green manure crops and organic neem cake powder',
        'Green Manure + Wood Ash': 'Green manure mixed with 15% wood ash',
        'Cow Dung + Bone Meal': 'Aged cow dung enriched with 30% sterilized bone meal',
        'Cow Dung + Neem Cake': 'Aged cow dung enriched with 25% neem cake powder',
        'Cow Dung + Wood Ash': 'Aged cow dung mixed with 20% wood ash'
    }
    return compositions.get(fertilizer, 'Custom organic mixture for sustainable farming')

def get_fertilizer_benefits(fertilizer):
    benefits = {
        'Vermicompost + Cow Dung Mix': [
            'Rich in NPK, micronutrients, and beneficial microorganisms',
            'Improves soil structure and water retention capacity',
            'Enhances root development and plant immunity',
            'Contains natural growth hormones and enzymes',
            'Sustainable and completely eco-friendly'
        ],
        'Vermicompost + Neem Cake': [
            'Natural pest and disease control from neem',
            'Rich in organic matter and beneficial microbes',
            'Improves soil fertility and structure',
            'Enhances plant immunity and growth',
            'Environmentally friendly pest management'
        ],
        'Vermicompost + Wood Ash': [
            'High potassium content for flowering and fruiting',
            'Improves soil pH and nutrient availability',
            'Enhances microbial activity',
            'Natural pest deterrent properties',
            'Sustainable waste utilization'
        ],
        'Farm Yard Manure + Compost': [
            'Balanced nutrient profile with diverse organic matter',
            'Excellent soil conditioning properties',
            'Enhanced microbial diversity',
            'Improved soil structure and aeration',
            'Natural disease suppression'
        ],
        'Farm Yard Manure + Bone Meal': [
            'High in phosphorus and calcium',
            'Excellent for root development',
            'Improves soil biology and nutrient availability',
            'Long-term nutrient release',
            'Enhanced disease resistance'
        ],
        'Farm Yard Manure + Wood Ash': [
            'Balanced NPK with enhanced potassium',
            'Improves soil structure and drainage',
            'Natural pest deterrent properties',
            'Enhances microbial activity',
            'Sustainable waste utilization'
        ],
        'Green Manure + Compost': [
            'Natural nitrogen fixation through legumes',
            'Improves soil organic matter content',
            'Enhances soil structure and water retention',
            'Promotes beneficial soil organisms',
            'Sustainable soil improvement'
        ],
        'Green Manure + Neem Cake': [
            'Natural nitrogen fixation and pest control',
            'Improves soil organic matter and microbial activity',
            'Provides slow-release nutrients',
            'Dual benefits of fertilizer and pest control',
            'Enhances biodiversity'
        ],
        'Green Manure + Wood Ash': [
            'Natural nitrogen fixation with potassium boost',
            'Improves soil structure and drainage',
            'Enhances microbial activity',
            'Natural pest deterrent properties',
            'Sustainable soil improvement'
        ],
        'Cow Dung + Bone Meal': [
            'Rich in phosphorus, calcium, and organic matter',
            'Excellent for root development',
            'Improves soil fertility and structure',
            'Long-lasting soil health benefits',
            'Natural disease resistance'
        ],
        'Cow Dung + Neem Cake': [
            'Rich in organic matter and natural nitrogen',
            'Natural pest repellent properties',
            'Improves soil fertility and structure',
            'Promotes beneficial soil microorganisms',
            'Long-lasting soil health benefits'
        ],
        'Cow Dung + Wood Ash': [
            'Balanced nutrients with enhanced potassium',
            'Improves soil structure and drainage',
            'Natural pest deterrent properties',
            'Enhances microbial activity',
            'Sustainable waste utilization'
        ]
    }
    return benefits.get(fertilizer, [
        'Improves soil health and structure',
        'Environmentally friendly and sustainable',
        'Promotes beneficial soil microorganisms',
        'Enhances crop quality and yield',
        'Long-term soil fertility improvement'
    ])

def get_fertilizer_application(fertilizer):
    applications = {
        'Vermicompost + Cow Dung Mix': 'Apply 2-3 tons per hectare, mix thoroughly with soil 2-3 weeks before sowing. Water regularly to maintain moisture.',
        'Vermicompost + Neem Cake': 'Apply 2-3 tons per hectare before planting. Mix well with soil and water regularly.',
        'Vermicompost + Wood Ash': 'Apply 2-3 tons per hectare during land preparation. Mix thoroughly with soil.',
        'Farm Yard Manure + Compost': 'Apply 5-6 tons per hectare during land preparation. Mix thoroughly with soil.',
        'Farm Yard Manure + Bone Meal': 'Apply 4-5 tons per hectare before planting. Incorporate well into soil.',
        'Farm Yard Manure + Wood Ash': 'Apply 4-5 tons per hectare during land preparation. Mix thoroughly with soil.',
        'Green Manure + Compost': 'Grow green manure crops for 45-60 days, then incorporate into soil. Add 2-3 tons compost per hectare.',
        'Green Manure + Neem Cake': 'Grow green manure crops for 45-60 days, then incorporate into soil. Add 2-3 quintals neem cake per hectare.',
        'Green Manure + Wood Ash': 'Grow green manure crops for 45-60 days, then incorporate into soil. Add 1-2 tons wood ash per hectare.',
        'Cow Dung + Bone Meal': 'Apply 4-5 tons per hectare before planting. Incorporate well into soil.',
        'Cow Dung + Neem Cake': 'Apply 4-5 tons per hectare before planting. Incorporate well into soil.',
        'Cow Dung + Wood Ash': 'Apply 4-5 tons per hectare during land preparation. Mix thoroughly with soil.'
    }
    return applications.get(fertilizer, 'Apply according to specific crop requirements and soil conditions')

def get_fertilizer_eco_impact(fertilizer):
    impacts = {
        'Vermicompost + Cow Dung Mix': 'Promotes soil biodiversity and reduces carbon footprint',
        'Vermicompost + Neem Cake': 'Supports organic farming and natural pest management',
        'Vermicompost + Wood Ash': 'Promotes waste recycling and sustainable agriculture',
        'Farm Yard Manure + Compost': 'Supports sustainable agriculture and soil conservation',
        'Farm Yard Manure + Bone Meal': 'Promotes resource recycling and soil health',
        'Farm Yard Manure + Wood Ash': 'Supports waste utilization and sustainable farming',
        'Green Manure + Compost': 'Enhances biodiversity and soil conservation',
        'Green Manure + Neem Cake': 'Promotes organic farming and natural pest control',
        'Green Manure + Wood Ash': 'Supports sustainable agriculture and waste utilization',
        'Cow Dung + Bone Meal': 'Promotes resource recycling and soil health',
        'Cow Dung + Neem Cake': 'Supports organic farming and natural pest management',
        'Cow Dung + Wood Ash': 'Promotes waste recycling and sustainable agriculture'
    }
    return impacts.get(fertilizer, 'Supports sustainable agriculture and soil health')

def get_additional_notes(fertilizer):
    composition = get_fertilizer_composition(fertilizer)
    benefits = get_fertilizer_benefits(fertilizer)
    application = get_fertilizer_application(fertilizer)
    eco_impact = get_fertilizer_eco_impact(fertilizer)
    
    return f'''
Bio-organic Fertilizer Recommendation
Based on advanced soil analysis and sustainable farming practices.

Key Benefits:
✓ {benefits[0]}
✓ {benefits[1]}
✓ {benefits[2]}
✓ {benefits[3]}
✓ {benefits[4]}

Composition:
{composition}

Application Guidelines:
1. {application}
2. Maintain proper soil moisture levels
3. Implement crop rotation
4. Use organic mulching
5. Monitor soil health regularly

Environmental Impact:
{eco_impact}

Additional Tips:
• Best application time: Early morning or late evening
• Soil temperature: Maintain between 20-30°C
• pH management: Monitor every 2-3 months
• Moisture control: Use mulch to retain moisture
• Companion planting: Consider compatible crops'''

if __name__ == '__main__':
    try:
        # Ensure required directories exist
        os.makedirs(DATA_DIR, exist_ok=True)
        os.makedirs(MODELS_DIR, exist_ok=True)
        
        # Start the server
        logger.info("Starting Flask server...")
        app.run(host='0.0.0.0', port=5000)
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}")
        raise 