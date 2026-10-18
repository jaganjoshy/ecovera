// soil_data_model.dart
class SoilData {
  final double nitrogen; // Nitrogen content in soil (mg/kg)
  final double phosphorus; // Phosphorus content in soil (mg/kg)
  final double potassium; // Potassium content in soil (mg/kg)
  final double temperature; // Soil temperature (°C)
  final double moisture; // Moisture percentage in soil (%)
  final double humidity; // Humidity percentage (%)
  final double ph; // Soil acidity level (e.g., 6.5)

  SoilData({
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.temperature,
    required this.moisture,
    required this.humidity,
    required this.ph,
  });
}
