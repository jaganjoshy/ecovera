import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soil_analyzer/model/soil_data_model.dart';
import 'package:soil_analyzer/service/ai_services.dart';
import 'package:soil_analyzer/widgets/soil_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SoilData? soilData;
  List<String>? suitableCrops;
  List<String>? fertilizers;
  final AIService _aiService = AIService();

  void _fetchSoilData() {
    // Mock data from T-Rod (replace with real hardware integration)
    setState(() {
      soilData = SoilData(
        nitrogen: 50.0,
        phosphorus: 30.0,
        potassium: 40.0,
        temperature: 25.0,
        moisture: 60.0,
        humidity: 70.0,
        ph: 6.5,
      );
      var predictions = _aiService.predict(soilData!);
      suitableCrops = predictions['crops'];
      fertilizers = predictions['fertilizers'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EcoVera - T-Rod Analysis',
          style: GoogleFonts.lobster(),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _fetchSoilData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                child: const Text('Analyze Soil with T-Rod'),
              ),
              const SizedBox(height: 20),
              if (soilData != null) ...[
                SoilCard(label: 'Nitrogen', value: soilData!.nitrogen),
                SoilCard(label: 'Phosphorus', value: soilData!.phosphorus),
                SoilCard(label: 'Potassium', value: soilData!.potassium),
                SoilCard(label: 'Temperature', value: soilData!.temperature),
                SoilCard(label: 'Moisture', value: soilData!.moisture),
                SoilCard(label: 'Humidity', value: soilData!.humidity),
                SoilCard(label: 'pH', value: soilData!.ph),
              ],
              const SizedBox(height: 20),
              if (suitableCrops != null && fertilizers != null) ...[
                Text(
                  'Suitable Crops:',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                Text(suitableCrops!.join(', '),
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                  'Recommended Fertilizers:',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                Text(fertilizers!.join(', '),
                    style: const TextStyle(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
