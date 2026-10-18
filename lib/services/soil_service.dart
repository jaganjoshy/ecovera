import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config.dart';

class SoilService {
  late SharedPreferences _prefs;
  final String baseUrl;
  bool _isInitialized = false;
  final Duration timeout = const Duration(seconds: 10);

  SoilService._({required this.baseUrl});

  static Future<SoilService> create() async {
    // Use localhost for web; change to your machine's IP for physical Android/iOS device
    final String url =
        kIsWeb ? 'http://localhost:5000' : 'http://localhost:5000';

    final service = SoilService._(baseUrl: url);
    try {
      await service.initialize();
    } catch (e) {
      print('Error during initialization, will use mock predictions: $e');
    }
    return service;
  }

  // Backwards compatible constructor
  factory SoilService() {
    throw Exception(
        'Please use SoilService.create() instead of the constructor.');
  }

  // Singleton instance for compatibility
  static SoilService? _instance;
  static Future<SoilService> get instance async {
    if (_instance == null) {
      _instance = await create();
    }
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      print('Checking backend health at $baseUrl/health');

      // Check backend health
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(
        timeout,
        onTimeout: () {
          print('Health check timed out after ${timeout.inSeconds} seconds');
          return http.Response('{"status": "timeout"}', 408);
        },
      );

      print('Health check response status: ${response.statusCode}');
      print('Health check response body: ${response.body}');

      if (response.statusCode == 200) {
        _isInitialized = true;
        print('SoilService initialized successfully with backend connection');
      } else {
        print('Backend is not available, will use mock predictions');
        _isInitialized = true;
      }
    } catch (e) {
      print('Backend is not available, will use mock predictions: $e');
      _isInitialized = true;
    }
  }

  Future<bool> checkBackendHealth() async {
    try {
      print('Checking backend health...');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(
        timeout,
        onTimeout: () {
          print('Health check timed out');
          return http.Response('{"status": "timeout"}', 408);
        },
      );

      print('Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> analyzeSoil(
      Map<String, dynamic> soilData) async {
    try {
      // Ensure service is initialized
      if (!_isInitialized) {
        await initialize();
      }

      // Check backend health
      final isHealthy = await checkBackendHealth();
      if (!isHealthy) {
        print('Backend is not available, using mock predictions');
        return _getMockPredictions(soilData);
      }

      // Convert soil data values to numbers with proper validation
      final processedData = {
        'nitrogen':
            double.tryParse(soilData['nitrogen']?.toString() ?? '') ?? 0.0,
        'phosphorus':
            double.tryParse(soilData['phosphorus']?.toString() ?? '') ?? 0.0,
        'potassium':
            double.tryParse(soilData['potassium']?.toString() ?? '') ?? 0.0,
        'temperature':
            double.tryParse(soilData['temperature']?.toString() ?? '') ?? 0.0,
        'moisture':
            double.tryParse(soilData['moisture']?.toString() ?? '') ?? 0.0,
        'humidity':
            double.tryParse(soilData['humidity']?.toString() ?? '') ?? 0.0,
        'ph': double.tryParse(soilData['ph']?.toString() ?? '') ?? 0.0,
        'rainfall':
            double.tryParse(soilData['rainfall']?.toString() ?? '') ?? 0.0,
      };

      print('Sending soil data to backend: $processedData');

      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(processedData),
          )
          .timeout(const Duration(seconds: 10));

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['suitable_crops'] != null &&
            data['recommended_fertilizers'] != null) {
          return {
            'suitable_crops': List<String>.from(data['suitable_crops']),
            'recommended_fertilizers':
                List<String>.from(data['recommended_fertilizers']),
            'confidence_score': data['confidence_score'] ?? 0.85,
            'additional_notes':
                data['additional_notes'] ?? 'No additional notes available',
          };
        } else {
          print('Invalid response format, using mock predictions');
          return _getMockPredictions(soilData);
        }
      } else {
        print('Error response from backend: ${response.statusCode}');
        return _getMockPredictions(soilData);
      }
    } catch (e) {
      print('Error in analyzeSoil: $e');
      return _getMockPredictions(soilData);
    }
  }

  Map<String, dynamic> _getMockPredictions(Map<String, dynamic> soilData) {
    try {
      final n = double.tryParse(soilData['nitrogen']?.toString() ?? '') ?? 0.0;
      final p =
          double.tryParse(soilData['phosphorus']?.toString() ?? '') ?? 0.0;
      final k = double.tryParse(soilData['potassium']?.toString() ?? '') ?? 0.0;
      final ph = double.tryParse(soilData['ph']?.toString() ?? '') ?? 0.0;
      final moisture =
          double.tryParse(soilData['moisture']?.toString() ?? '') ?? 0.0;

      // Determine suitable crops based on NPK values
      List<String> crops = [];
      if (n > 50 && p > 30 && k > 40) {
        crops = ['Rice', 'Wheat', 'Maize'];
      } else if (n > 40 && p > 20 && k > 30) {
        crops = ['Cotton', 'Sugarcane', 'Groundnut'];
      } else {
        crops = ['Millets', 'Pulses', 'Oilseeds'];
      }

      // Determine bio fertilizers based on deficiencies
      List<String> fertilizers = [];
      if (n < 30) fertilizers.add('Cow Dung Manure');
      if (p < 20) fertilizers.add('Vermicompost');
      if (k < 30) fertilizers.add('Neem Cake');
      if (fertilizers.isEmpty) {
        fertilizers = ['Farm Yard Manure', 'Vermicompost + Cow Dung Mix'];
      }

      return {
        'suitable_crops': crops,
        'recommended_fertilizers': fertilizers,
        'confidence_score': 0.85,
        'additional_notes': '''
Soil Analysis Summary:
- N-P-K Levels: $n-$p-$k
- pH Level: $ph
- Moisture: $moisture%

Crop Recommendations:
${crops.map((crop) => "• $crop").join("\n")}

Bio Fertilizer Recommendations:
${fertilizers.map((fert) => "• $fert").join("\n")}

Detailed Farming Advice:

Soil Management:
• Maintain optimal soil moisture between 40-60%
• Monitor pH levels regularly
• Implement crop rotation to maintain soil health
• Use organic mulching to retain moisture
• Practice no-till farming to preserve soil structure

Nutrient Management:
• Apply bio fertilizers in split doses
• Use vermicompost for long-term soil health
• Monitor nutrient levels every 2-3 months
• Consider foliar feeding with organic solutions
• Use green manure crops for natural nitrogen fixation

Water Management:
• Implement drip irrigation for efficient water use
• Schedule irrigation based on soil moisture
• Monitor rainfall patterns
• Use rainwater harvesting techniques
• Practice mulching to reduce water evaporation

Pest and Disease Control:
• Practice integrated pest management
• Use neem-based solutions for pest control
• Maintain proper plant spacing
• Monitor for early signs of disease
• Use companion planting for natural pest control

Climate Adaptation:
• Choose climate-resilient crop varieties
• Implement shade management
• Use windbreaks for protection
• Monitor temperature variations
• Practice crop diversification

Sustainable Practices:
• Practice conservation tillage
• Use cover crops
• Implement agroforestry
• Maintain biodiversity
• Use crop rotation to break pest cycles

Note: These recommendations are based on soil parameter analysis.
For best results, consider local conditions and expert consultation.
''',
      };
    } catch (e) {
      print('Error in mock predictions: $e');
      return {
        'suitable_crops': ['Rice', 'Wheat', 'Maize'],
        'recommended_fertilizers': ['Farm Yard Manure', 'Vermicompost'],
        'confidence_score': 0.85,
        'additional_notes':
            'These are mock predictions based on basic soil parameters. For more accurate results, please ensure the backend server is running.',
      };
    }
  }

  Future<void> _storeAnalysisResults(
    Map<String, dynamic> soilData,
    Map<String, dynamic> predictions,
  ) async {
    try {
      final analyses = await _prefs.getStringList('soil_analyses') ?? [];
      final analysis = jsonEncode({
        'soilData': soilData,
        'predictions': predictions,
        'timestamp': DateTime.now().toIso8601String(),
      });
      analyses.add(analysis);
      await _prefs.setStringList('soil_analyses', analyses);
    } catch (e) {
      await _logError('Failed to store analysis results: $e');
    }
  }

  Future<void> _logError(String error) async {
    try {
      final errors = await _prefs.getStringList('errors') ?? [];
      final errorLog = jsonEncode({
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      });
      errors.add(errorLog);
      await _prefs.setStringList('errors', errors);
    } catch (_) {
      // Ignore errors when logging errors
    }
  }
}
