import 'package:flutter/material.dart';
import '../models/feature_card_model.dart';

class FeatureCardWidget extends StatelessWidget {
  final FeatureCardModel feature;

  const FeatureCardWidget({required this.feature, super.key});

  @override
  Widget build(BuildContext context) {
    final Color active = const Color(0xFF2563EB);

    return SizedBox(
      height: 250, // Yükseklik artırıldı
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: active.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(feature.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              feature.title,
              style: TextStyle(
                color: active,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              feature.description,
              style: TextStyle(color: Colors.blueGrey[700], fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: feature.isEnabled ? feature.onPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: feature.isEnabled
                      ? active
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  feature.buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
