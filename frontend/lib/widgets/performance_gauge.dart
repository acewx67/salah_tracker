import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:salah_tracker/config/theme.dart';

/// Circular radial gauge for performance score display.
class PerformanceGauge extends StatelessWidget {
  final double score;
  final double size;

  const PerformanceGauge({
    super.key,
    required this.score,
    this.size = 250,
  });

  Color _getColor() {
    if (score >= 80) return AppTheme.gaugeGreen;
    if (score >= 60) return AppTheme.gaugeYellow;
    return AppTheme.gaugeRed;
  }

  String _getLabel() {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return SizedBox(
      width: size,
      height: size,
      child: SfRadialGauge(
        enableLoadingAnimation: true,
        animationDuration: 1500,
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 100,
            startAngle: 135,
            endAngle: 405,
            showLabels: false,
            showTicks: false,
            radiusFactor: 0.85,
            axisLineStyle: AxisLineStyle(
              thickness: 0.12,
              thicknessUnit: GaugeSizeUnit.factor,
              color: Colors.grey.shade200,
              cornerStyle: CornerStyle.bothCurve,
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: score,
                width: 0.12,
                sizeUnit: GaugeSizeUnit.factor,
                color: color,
                cornerStyle: CornerStyle.bothCurve,
                gradient: SweepGradient(
                  colors: [
                    color.withOpacity(0.6),
                    color,
                  ],
                ),
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                positionFactor: 0,
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getLabel(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
