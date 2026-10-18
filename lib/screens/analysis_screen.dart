import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/soil_service.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  late SoilService _soilService;
  bool isLoading = false;
  bool hasResults = false;
  bool isPro = true; // Pro version enabled
  Map<String, dynamic>? results;
  bool isBackendHealthy = false;
  String? error;

  final Map<String, TextEditingController> controllers = {
    'nitrogen': TextEditingController(),
    'phosphorus': TextEditingController(),
    'potassium': TextEditingController(),
    'temperature': TextEditingController(),
    'moisture': TextEditingController(),
    'humidity': TextEditingController(),
    'ph': TextEditingController(),
    'rainfall': TextEditingController(),
  };

  List<String> crops = [];
  List<String> fertilizers = [];
  String? farmingAdvice;

  // Add TextEditingController declarations at the top of the class
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _moistureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _soilService = await SoilService.instance;
      final isHealthy = await _soilService.checkBackendHealth();
      setState(() {
        isBackendHealthy = isHealthy;
      });

      if (!isHealthy && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backend is not available. Using mock predictions.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize service: $e'),
            backgroundColor: const Color.fromARGB(255, 236, 65, 53),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    controllers.values.forEach((controller) => controller.dispose());
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _temperatureController.dispose();
    _moistureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSoil() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Collect soil data with null safety
      final soilData = {
        'nitrogen': double.tryParse(_nitrogenController.text.trim()) ?? 0.0,
        'phosphorus': double.tryParse(_phosphorusController.text.trim()) ?? 0.0,
        'potassium': double.tryParse(_potassiumController.text.trim()) ?? 0.0,
        'temperature':
            double.tryParse(_temperatureController.text.trim()) ?? 0.0,
        'moisture': double.tryParse(_moistureController.text.trim()) ?? 0.0,
        'humidity': double.tryParse(_humidityController.text.trim()) ?? 0.0,
        'ph': double.tryParse(_phController.text.trim()) ?? 0.0,
        'rainfall': double.tryParse(_rainfallController.text.trim()) ?? 0.0,
      };

      // Validate that at least one parameter is provided
      bool hasValidInput = soilData.values.any((value) => value > 0);
      if (!hasValidInput) {
        throw Exception('Please provide at least one soil parameter');
      }

      // Get predictions from the service
      final results = await _soilService.analyzeSoil(soilData);
      if (results == null) {
        throw Exception('Failed to get predictions');
      }

      // Generate soil texture analysis based on NPK values
      final soilTextureAnalysis = _generateSoilTextureAnalysis(
          soilData['nitrogen']!,
          soilData['phosphorus']!,
          soilData['potassium']!);

      setState(() {
        isLoading = false;
      });

      // Navigate to results screen with all required parameters
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            results: results,
            soilData: soilData,
            soilTextureAnalysis: soilTextureAnalysis,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  String _generateSoilTextureAnalysis(double n, double p, double k) {
    // Calculate total NPK
    double total = n + p + k;
    if (total == 0) return 'Insufficient data for soil texture analysis';

    // Calculate percentages
    double nPercent = (n / total) * 100;
    double pPercent = (p / total) * 100;
    double kPercent = (k / total) * 100;

    // Determine soil texture based on NPK ratios
    if (nPercent > 40) {
      return 'Clay-rich soil with high nitrogen content';
    } else if (pPercent > 40) {
      return 'Loamy soil with good phosphorus content';
    } else if (kPercent > 40) {
      return 'Sandy soil with high potassium content';
    } else {
      return 'Well-balanced soil composition';
    }
  }

  String _generateFarmingAdvice(List<String> crops, List<String> fertilizers) {
    if (crops.isEmpty || fertilizers.isEmpty) {
      return 'Unable to generate farming advice at this time.';
    }

    final cropList = crops.map((crop) => '  • $crop').join('\n');
    final fertilizerList = fertilizers.map((fert) => '  • $fert').join('\n');

    return '''
Based on the soil analysis, here are the recommended practices:

1. Recommended Crops:
$cropList

2. Recommended Fertilizers:
$fertilizerList

3. Soil Management:
   • Maintain proper soil moisture levels
   • Monitor pH regularly
   • Implement crop rotation
   • Use organic mulching to retain moisture

4. Additional Tips:
   • Regular soil testing is recommended
   • Consider companion planting
   • Monitor for pests and diseases
   • Maintain proper irrigation schedule
''';
  }

  String getSoilTextureAnalysis(Map<String, dynamic> soilData) {
    double nitrogen = soilData['nitrogen'] ?? 0.0;
    double phosphorus = soilData['phosphorus'] ?? 0.0;
    double potassium = soilData['potassium'] ?? 0.0;
    double moisture = soilData['moisture'] ?? 0.0;

    if (nitrogen == 0.0 && phosphorus == 0.0 && potassium == 0.0) {
      return 'Insufficient data to determine soil texture.';
    }

    // Basic soil texture analysis based on NPK values
    String texture = '';
    if (nitrogen > 60 && phosphorus > 40 && potassium > 30) {
      texture = 'Rich Loamy Soil';
    } else if (nitrogen > 40 && moisture > 30) {
      texture = 'Clay Loam';
    } else if (phosphorus > 30 && moisture < 20) {
      texture = 'Sandy Loam';
    } else {
      texture = 'Standard Loam';
    }

    return '''
Soil Texture Classification: $texture

Analysis based on:
- Nitrogen content: ${nitrogen.toStringAsFixed(1)}%
- Phosphorus content: ${phosphorus.toStringAsFixed(1)}%
- Potassium content: ${potassium.toStringAsFixed(1)}%
- Moisture level: ${moisture.toStringAsFixed(1)}%

This texture indicates the soil's physical properties and its capacity to retain nutrients and water.
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Soil Nutrition Analyzer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Soil Parameters',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Please enter the following soil parameters to analyze and get recommendations:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildParameterInput('Nitrogen', 'mg/kg',
                              Icons.science, _nitrogenController),
                          _buildParameterInput('Phosphorus', 'mg/kg',
                              Icons.science, _phosphorusController),
                          _buildParameterInput('Potassium', 'mg/kg',
                              Icons.science, _potassiumController),
                          _buildParameterInput('Temperature', '°C',
                              Icons.thermostat, _temperatureController),
                          _buildParameterInput('Moisture', '%',
                              Icons.water_drop, _moistureController),
                          _buildParameterInput('Humidity', '%', Icons.water,
                              _humidityController),
                          _buildParameterInput(
                              'pH', '', Icons.science_outlined, _phController),
                          _buildParameterInput('Rainfall', 'mm',
                              Icons.cloudy_snowing, _rainfallController),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _analyzeSoil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Analyze Soil',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (hasResults) _buildResultsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterInput(String label, String unit, IconData icon,
      TextEditingController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.0',
                suffixText: unit,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Results',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            if (results != null) ...[
              _buildResultSection(
                'Suitable Crops',
                crops,
                Icons.eco,
                Colors.green,
              ),
              _buildResultSection(
                'Recommended Fertilizers',
                fertilizers,
                Icons.science,
                Colors.blue,
              ),
              if (farmingAdvice != null && farmingAdvice!.isNotEmpty) ...[
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Farming Advice',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...farmingAdvice!.split('\n').map((advice) {
                          if (advice.trim().isEmpty)
                            return const SizedBox(height: 8);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    advice.trim(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(
      String title, List<String> items, IconData icon, Color color) {
    // Special styling for Bio Fertilizers section
    final isBioFertilizer = title == 'Recommended Fertilizers';
    final sectionTitle = isBioFertilizer ? 'Bio Fertilizers' : title;
    final sectionColor = isBioFertilizer ? Colors.green[700]! : color;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: isBioFertilizer
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: sectionColor,
                  size: isBioFertilizer ? 28 : 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: sectionColor,
                    ),
                  ),
                ),
                if (isBioFertilizer) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ECO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (isBioFertilizer)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Environmentally friendly natural fertilizers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isBioFertilizer
                            ? Icons.eco_outlined
                            : Icons.check_circle,
                        color: sectionColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;
  final Map<String, dynamic> soilData;
  final String soilTextureAnalysis;

  const ResultsScreen({
    Key? key,
    required this.results,
    required this.soilData,
    required this.soilTextureAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final crops = List<String>.from(results['suitable_crops'] ?? []);
    final fertilizers =
        List<String>.from(results['recommended_fertilizers'] ?? []);
    final farmingAdvice = results['additional_notes'] as String?;
    final confidenceScore = (results['confidence_score'] as double?) ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analysis Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Confidence Score Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.green[700],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Overall Confidence',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(confidenceScore * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Results Cards
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResultSection(
                        'Suitable Crops',
                        crops,
                        Icons.eco,
                        Colors.green,
                      ),
                      _buildResultSection(
                        'Recommended Fertilizers',
                        fertilizers,
                        Icons.science,
                        Colors.blue,
                      ),
                      if (farmingAdvice != null && farmingAdvice.isNotEmpty)
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Farming Advice',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...farmingAdvice.split('\n').map((advice) {
                                  if (advice.trim().isEmpty)
                                    return const SizedBox(height: 8);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            advice.trim(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      // New analysis option display
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Soil Texture Analysis',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                soilTextureAnalysis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              // New Analysis Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => AnalysisScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'New Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection(
      String title, List<String> items, IconData icon, Color color) {
    // Special styling for Bio Fertilizers section
    final isBioFertilizer = title == 'Recommended Fertilizers';
    final sectionTitle = isBioFertilizer ? 'Bio Fertilizers' : title;
    final sectionColor = isBioFertilizer ? Colors.green[700]! : color;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: isBioFertilizer
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: sectionColor,
                  size: isBioFertilizer ? 28 : 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: sectionColor,
                    ),
                  ),
                ),
                if (isBioFertilizer) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ECO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (isBioFertilizer)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Environmentally friendly natural fertilizers',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        isBioFertilizer
                            ? Icons.eco_outlined
                            : Icons.check_circle,
                        color: sectionColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF757575),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
