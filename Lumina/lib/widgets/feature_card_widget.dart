import 'package:flutter/material.dart';
import '../models/feature_card_model.dart';

class FeatureCardWidget extends StatelessWidget {
  final FeatureCardModel feature;

  const FeatureCardWidget({required this.feature, super.key});

  @override
  Widget build(BuildContext context) {
    final Color active = const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: active.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(feature.icon, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(
            feature.title,
            style: TextStyle(
              color: active,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: TextStyle(color: Colors.blueGrey[700], fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: feature.isEnabled ? feature.onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: feature.isEnabled ? active : Colors.grey[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(double.infinity, 42),
            ),
            child: Text(
              feature.buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
