class DailyDeal {
  final int id;
  final String label;
  final String subtitle;
  final String tag;

  const DailyDeal({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.tag,
  });

  factory DailyDeal.fromJson(Map<String, dynamic> json) {
    return DailyDeal(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      label: (json['label'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      tag: (json['tag'] ?? '').toString(),
    );
  }
}

class RewardsSummary {
  final int points;
  final String tier;
  final String nextTier;
  final int nextTierPoints;
  final double progress;
  final String earnedLabel;
  final String goalLabel;

  const RewardsSummary({
    required this.points,
    required this.tier,
    required this.nextTier,
    required this.nextTierPoints,
    required this.progress,
    required this.earnedLabel,
    required this.goalLabel,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    final progressRaw = json['progress'];
    final progress = progressRaw is num
        ? progressRaw.toDouble()
        : double.tryParse('$progressRaw') ?? 0;
    return RewardsSummary(
      points: json['points'] is int
          ? json['points'] as int
          : int.tryParse('${json['points']}') ?? 0,
      tier: (json['tier'] ?? '').toString(),
      nextTier: (json['next_tier'] ?? '').toString(),
      nextTierPoints: json['next_tier_points'] is int
          ? json['next_tier_points'] as int
          : int.tryParse('${json['next_tier_points']}') ?? 0,
      progress: progress.clamp(0, 1),
      earnedLabel: (json['earned_label'] ?? '').toString(),
      goalLabel: (json['goal_label'] ?? '').toString(),
    );
  }

  String get pointsLabel {
    final text = points.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }
}
