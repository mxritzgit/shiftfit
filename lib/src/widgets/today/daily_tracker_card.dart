import 'package:flutter/material.dart';

import '../../services/health_service.dart';
import '../../theme/app_colors.dart';
import '../common/basic_widgets.dart';

class TrackerStat {
  const TrackerStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.ratio,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double ratio;
}

class DailyTrackerCard extends StatelessWidget {
  const DailyTrackerCard({
    super.key,
    required this.stats,
    this.healthAuthState = HealthAuthState.unsupported,
    this.healthLastFetch,
    this.onConnectHealth,
    this.onRefreshHealth,
  });

  final List<TrackerStat> stats;
  final HealthAuthState healthAuthState;
  final DateTime? healthLastFetch;
  final VoidCallback? onConnectHealth;
  final VoidCallback? onRefreshHealth;

  bool get _healthSupported =>
      healthAuthState != HealthAuthState.unsupported &&
      onConnectHealth != null &&
      onRefreshHealth != null;

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final connected = healthAuthState == HealthAuthState.granted;
    return AppCard(
      key: const ValueKey('daily-tracker-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tageswerte',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              if (_healthSupported)
                InkWell(
                  onTap: connected ? onRefreshHealth : onConnectHealth,
                  borderRadius: BorderRadius.circular(rChip),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: connected
                          ? lime.withValues(alpha: 0.12)
                          : surfaceSoft,
                      borderRadius: BorderRadius.circular(rChip),
                      border: Border.all(
                        color: connected
                            ? lime.withValues(alpha: 0.35)
                            : hairline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connected
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline,
                          color: connected ? lime : textMuted,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          connected && healthLastFetch != null
                              ? _formatTime(healthLastFetch!)
                              : connected
                                  ? 'Health'
                                  : 'verbinden',
                          style: TextStyle(
                            color: connected ? lime : textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                Expanded(child: _StatCell(stat: stats[i])),
                if (i != stats.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat});

  final TrackerStat stat;

  @override
  Widget build(BuildContext context) {
    final double clamped = stat.ratio.clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(stat.icon, color: stat.color, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                stat.label,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          stat.value,
          style: TextStyle(
            color: stat.color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(rPill),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 3,
            backgroundColor: hairline,
            color: stat.color,
          ),
        ),
      ],
    );
  }
}
