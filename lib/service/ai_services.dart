// ai_service.dart
import 'package:soil_analyzer/model/soil_data_model.dart';

class AIService {
  Map<String, List<String>> predict(SoilData data) {
    List<String> crops = [];
    List<String> fertilizers = [];

    // Crop prediction based on soil data
    if (data.ph >= 6.0 && data.ph <= 7.5 && data.nitrogen > 40) {
      crops.add('Wheat');
      crops.add('Corn');
    }
    if (data.ph >= 5.5 && data.ph <= 7.0 && data.phosphorus > 20) {
      crops.add('Soybean');
    }
    if (data.potassium > 30 && data.moisture > 50) {
      crops.add('Rice');
    }

    // Fertilizer prediction
    if (data.nitrogen < 50) {
      fertilizers.add('Urea');
    }
    if (data.phosphorus < 30) {
      fertilizers.add('DAP');
    }
    if (data.potassium < 40) {
      fertilizers.add('Muriate of Potash');
    }

    // For debugging, print the results (remove in production)
    print('Predicted Crops: $crops');
    print('Recommended Fertilizers: $fertilizers');

    return {'crops': crops, 'fertilizers': fertilizers};
  }
}
