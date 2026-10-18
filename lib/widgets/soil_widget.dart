import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoilCard extends StatelessWidget {
  final String label;
  final double value;

  const SoilCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
            ),
            Text(
              value.toStringAsFixed(1),
              style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
