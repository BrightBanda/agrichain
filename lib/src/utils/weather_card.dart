import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A weather reading plus the farming advice derived from it.
///
/// There is no weather provider wired into AgriChain yet, so screens pass
/// [WeatherSnapshot.placeholder]. The widget itself is real — swap in a live
/// service and nothing here changes.
class WeatherSnapshot {
  final String location;
  final String condition;
  final int temperatureC;
  final int humidityPercent;
  final int windKph;
  final String advice;

  /// True when the values are stand-ins rather than a real forecast, so the
  /// card can say so instead of quietly misleading a farmer.
  final bool isPlaceholder;

  const WeatherSnapshot({
    required this.location,
    required this.condition,
    required this.temperatureC,
    required this.humidityPercent,
    required this.windKph,
    required this.advice,
    this.isPlaceholder = false,
  });

  /// Stand-in used until a weather provider is integrated.
  static WeatherSnapshot placeholder(String location) => WeatherSnapshot(
    location: location.isEmpty ? 'Malawi' : location,
    condition: 'Partly Sunny',
    temperatureC: 24,
    humidityPercent: 78,
    windKph: 12,
    advice:
        'Good time to apply Urea fertilizer on your maize before the next '
        'rains.',
    isPlaceholder: true,
  );
}

class WeatherCard extends StatelessWidget {
  final WeatherSnapshot weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4D6),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    size: 20,
                    color: Color(0xFFE0A100),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              weather.location,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHeading,
                              ),
                            ),
                          ),
                          if (weather.isPlaceholder) ...[
                            const SizedBox(width: 6),
                            Text(
                              'SAMPLE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weather.condition,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${weather.temperatureC}°C',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop_outlined,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        Text(
                          ' ${weather.humidityPercent}%  ',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Icon(
                          Icons.air,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        Text(
                          ' ${weather.windKph} km/h',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Farmer Weather Advice: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        TextSpan(text: weather.advice),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
