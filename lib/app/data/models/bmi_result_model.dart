class BmiInfoRow {
  final String label;
  final String value;
  final String? iconKey;

  const BmiInfoRow({
    required this.label,
    required this.value,
    this.iconKey,
  });
}

class BmiResult {
  final double bmi;
  final String category;
  final String unit;
  final double healthyBmiMin;
  final double healthyBmiMax;
  final double? healthyWeightMin;
  final double? healthyWeightMax;
  final double? bmiPrime;
  final double? ponderalIndex;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final bool fromApi;
  final String? message;
  final List<BmiInfoRow> infoRows;

  const BmiResult({
    required this.bmi,
    required this.category,
    this.unit = 'kg/m²',
    this.healthyBmiMin = 18.5,
    this.healthyBmiMax = 25,
    this.healthyWeightMin,
    this.healthyWeightMax,
    this.bmiPrime,
    this.ponderalIndex,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.fromApi = false,
    this.message,
    this.infoRows = const [],
  });

  /// Prefer API values; fill gaps from local fallback.
  factory BmiResult.mergeApiWithFallback({
    required Map<String, dynamic> apiData,
    required BmiResult fallback,
  }) {
    final parsed = BmiResult.fromJson(apiData, fallback: fallback);
    if (parsed.bmi <= 0) return fallback;

    final rows = parsed.infoRows.isNotEmpty
        ? parsed.infoRows
        : fallback.infoRows;

    return BmiResult(
      bmi: parsed.bmi > 0 ? parsed.bmi : fallback.bmi,
      category: parsed.category.trim().isNotEmpty
          ? parsed.category
          : fallback.category,
      unit: parsed.unit.trim().isNotEmpty ? parsed.unit : fallback.unit,
      healthyBmiMin: parsed.healthyBmiMin,
      healthyBmiMax: parsed.healthyBmiMax,
      healthyWeightMin: parsed.healthyWeightMin ?? fallback.healthyWeightMin,
      healthyWeightMax: parsed.healthyWeightMax ?? fallback.healthyWeightMax,
      bmiPrime: parsed.bmiPrime ?? fallback.bmiPrime,
      ponderalIndex: parsed.ponderalIndex ?? fallback.ponderalIndex,
      age: parsed.age ?? fallback.age,
      gender: parsed.gender ?? fallback.gender,
      heightCm: parsed.heightCm ?? fallback.heightCm,
      weightKg: parsed.weightKg ?? fallback.weightKg,
      fromApi: true,
      message: parsed.message,
      infoRows: rows,
    );
  }

  factory BmiResult.fromJson(
    Map<String, dynamic> json, {
    BmiResult? fallback,
  }) {
    double? d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      // "20.1 kg/m²" → 20.1
      final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(s);
      return m == null ? null : double.tryParse(m.group(0)!);
    }

    String? s(dynamic v) {
      if (v == null) return null;
      final t = v.toString().trim();
      if (t.isEmpty || t.toLowerCase() == 'null') return null;
      return t;
    }

    (double?, double?) rangeOf(dynamic raw) {
      if (raw == null) return (null, null);
      if (raw is Map) {
        return (
          d(raw['min'] ?? raw['from'] ?? raw['start'] ?? raw['lower']),
          d(raw['max'] ?? raw['to'] ?? raw['end'] ?? raw['upper']),
        );
      }
      final text = raw.toString();
      final parts = RegExp(r'-?\d+(\.\d+)?')
          .allMatches(text)
          .map((m) => double.tryParse(m.group(0)!))
          .whereType<double>()
          .toList();
      if (parts.length >= 2) return (parts[0], parts[1]);
      if (parts.length == 1) return (parts[0], null);
      return (null, null);
    }

    final bmi = d(json['bmi'] ??
            json['bmi_value'] ??
            json['value'] ??
            json['bmi_score'] ??
            json['result']) ??
        fallback?.bmi ??
        0;

    final height = d(json['height'] ?? json['height_cm'] ?? json['height_in_cm']);
    final weight = d(json['weight'] ?? json['weight_kg'] ?? json['weight_in_kg']);

    final bmiRange = rangeOf(json['healthy_bmi_range'] ??
        json['healthy_range'] ??
        json['bmi_range'] ??
        json['normal_bmi_range']);
    final weightRange = rangeOf(json['healthy_weight_for_the_height'] ??
        json['healthy_weight_for_height'] ??
        json['healthy_weight_range'] ??
        json['healthy_weight'] ??
        json['ideal_weight_range']);

    final healthyBmiMin = d(json['healthy_bmi_min'] ??
            json['healthy_range_min'] ??
            json['min_healthy_bmi'] ??
            json['bmi_min']) ??
        bmiRange.$1 ??
        fallback?.healthyBmiMin ??
        18.5;
    final healthyBmiMax = d(json['healthy_bmi_max'] ??
            json['healthy_range_max'] ??
            json['max_healthy_bmi'] ??
            json['bmi_max']) ??
        bmiRange.$2 ??
        fallback?.healthyBmiMax ??
        25;

    final healthyWeightMin = d(json['healthy_weight_min'] ??
            json['healthy_weight_for_height_min'] ??
            json['min_healthy_weight'] ??
            json['weight_min']) ??
        weightRange.$1 ??
        fallback?.healthyWeightMin;
    final healthyWeightMax = d(json['healthy_weight_max'] ??
            json['healthy_weight_for_height_max'] ??
            json['max_healthy_weight'] ??
            json['weight_max']) ??
        weightRange.$2 ??
        fallback?.healthyWeightMax;

    final bmiPrime = d(json['bmi_prime'] ?? json['bmiPrime'] ?? json['prime']);
    final ponderal = d(json['ponderal_index'] ??
        json['ponderalIndex'] ??
        json['ponderal']);

    final category = s(json['category'] ??
            json['bmi_category'] ??
            json['status'] ??
            json['classification'] ??
            json['label']) ??
        (bmi > 0 ? categoryForBmi(bmi) : (fallback?.category ?? 'Normal'));

    final unit = s(json['unit'] ?? json['bmi_unit']) ??
        fallback?.unit ??
        'kg/m²';

    final infoRows = _buildInfoRows(
      json: json,
      unit: unit,
      healthyBmiMin: healthyBmiMin,
      healthyBmiMax: healthyBmiMax,
      healthyWeightMin: healthyWeightMin,
      healthyWeightMax: healthyWeightMax,
      bmiPrime: bmiPrime,
      ponderalIndex: ponderal,
      fallbackRows: fallback?.infoRows ?? const [],
    );

    return BmiResult(
      bmi: bmi,
      category: category,
      unit: unit,
      healthyBmiMin: healthyBmiMin,
      healthyBmiMax: healthyBmiMax,
      healthyWeightMin: healthyWeightMin,
      healthyWeightMax: healthyWeightMax,
      bmiPrime: bmiPrime ?? fallback?.bmiPrime,
      ponderalIndex: ponderal ?? fallback?.ponderalIndex,
      age: int.tryParse('${json['age'] ?? ''}') ?? fallback?.age,
      gender: s(json['gender']) ?? fallback?.gender,
      heightCm: height ?? fallback?.heightCm,
      weightKg: weight ?? fallback?.weightKg,
      fromApi: true,
      message: s(json['message'] ?? json['note'] ?? json['summary']),
      infoRows: infoRows,
    );
  }

  /// Local fallback when API fails / empty.
  factory BmiResult.calculate({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
  }) {
    final h = heightCm / 100.0;
    final bmi = weightKg / (h * h);
    final minW = 18.5 * h * h;
    final maxW = 25.0 * h * h;
    final prime = bmi / 25.0;
    final ponderal = weightKg / (h * h * h);
    final roundedBmi = double.parse(bmi.toStringAsFixed(1));
    final category = categoryForBmi(bmi);

    final rows = <BmiInfoRow>[
      const BmiInfoRow(
        label: 'Healthy BMI range',
        value: '18.5 kg/m² – 25 kg/m²',
        iconKey: 'range',
      ),
      BmiInfoRow(
        label: 'Healthy weight for height',
        value:
            '${minW.toStringAsFixed(1)} – ${maxW.toStringAsFixed(1)} kg',
        iconKey: 'weight',
      ),
      BmiInfoRow(
        label: 'BMI Prime',
        value: prime.toStringAsFixed(1),
        iconKey: 'prime',
      ),
      BmiInfoRow(
        label: 'Ponderal Index',
        value: '${ponderal.toStringAsFixed(1)} kg/m³',
        iconKey: 'ponderal',
      ),
    ];

    return BmiResult(
      bmi: roundedBmi,
      category: category,
      healthyBmiMin: 18.5,
      healthyBmiMax: 25,
      healthyWeightMin: double.parse(minW.toStringAsFixed(1)),
      healthyWeightMax: double.parse(maxW.toStringAsFixed(1)),
      bmiPrime: double.parse(prime.toStringAsFixed(1)),
      ponderalIndex: double.parse(ponderal.toStringAsFixed(1)),
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      fromApi: false,
      infoRows: rows,
    );
  }

  static List<BmiInfoRow> _buildInfoRows({
    required Map<String, dynamic> json,
    required String unit,
    required double healthyBmiMin,
    required double healthyBmiMax,
    required double? healthyWeightMin,
    required double? healthyWeightMax,
    required double? bmiPrime,
    required double? ponderalIndex,
    required List<BmiInfoRow> fallbackRows,
  }) {
    final rows = <BmiInfoRow>[];

    // 1) Explicit list from API: details / info / summary_items
    final listKeys = ['details', 'info', 'summary', 'summary_items', 'rows'];
    for (final key in listKeys) {
      final raw = json[key];
      if (raw is! List) continue;
      for (final item in raw) {
        if (item is! Map) continue;
        final label = (item['label'] ??
                item['title'] ??
                item['name'] ??
                item['key'] ??
                '')
            .toString()
            .trim();
        final value = (item['value'] ?? item['text'] ?? item['description'] ?? '')
            .toString()
            .trim();
        if (label.isEmpty || value.isEmpty) continue;
        rows.add(BmiInfoRow(label: _prettyLabel(label), value: value));
      }
      if (rows.isNotEmpty) return rows;
    }

    // 2) Known dynamic string fields (as-is from API)
    void addIfPresent(String key, String label, {String? iconKey}) {
      final v = json[key];
      if (v == null) return;
      final text = v.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return;
      // Skip plain maps/lists already handled
      if (v is Map || v is List) {
        if (v is Map) {
          final min = v['min'] ?? v['from'];
          final max = v['max'] ?? v['to'];
          if (min != null && max != null) {
            rows.add(BmiInfoRow(
              label: label,
              value: '$min – $max',
              iconKey: iconKey,
            ));
          }
        }
        return;
      }
      rows.add(BmiInfoRow(label: label, value: text, iconKey: iconKey));
    }

    addIfPresent('healthy_bmi_range', 'Healthy BMI range', iconKey: 'range');
    addIfPresent('healthy_range', 'Healthy BMI range', iconKey: 'range');
    addIfPresent('healthy_weight_for_the_height', 'Healthy weight for height',
        iconKey: 'weight');
    addIfPresent('healthy_weight_for_height', 'Healthy weight for height',
        iconKey: 'weight');
    addIfPresent('healthy_weight_range', 'Healthy weight for height',
        iconKey: 'weight');
    addIfPresent('bmi_prime', 'BMI Prime', iconKey: 'prime');
    addIfPresent('ponderal_index', 'Ponderal Index', iconKey: 'ponderal');

    // 3) Compose from numeric fields if string fields weren't present
    final hasRange =
        rows.any((r) => r.label.toLowerCase().contains('healthy bmi'));
    if (!hasRange) {
      rows.add(BmiInfoRow(
        label: 'Healthy BMI range',
        value:
            '${healthyBmiMin.toStringAsFixed(1)} $unit – ${healthyBmiMax.toStringAsFixed(1)} $unit',
        iconKey: 'range',
      ));
    }
    final hasWeight =
        rows.any((r) => r.label.toLowerCase().contains('healthy weight'));
    if (!hasWeight && healthyWeightMin != null && healthyWeightMax != null) {
      rows.add(BmiInfoRow(
        label: 'Healthy weight for height',
        value:
            '${healthyWeightMin.toStringAsFixed(1)} – ${healthyWeightMax.toStringAsFixed(1)} kg',
        iconKey: 'weight',
      ));
    }
    final hasPrime = rows.any((r) => r.label.toLowerCase().contains('prime'));
    if (!hasPrime && bmiPrime != null) {
      rows.add(BmiInfoRow(
        label: 'BMI Prime',
        value: bmiPrime.toStringAsFixed(1),
        iconKey: 'prime',
      ));
    }
    final hasPonderal =
        rows.any((r) => r.label.toLowerCase().contains('ponderal'));
    if (!hasPonderal && ponderalIndex != null) {
      rows.add(BmiInfoRow(
        label: 'Ponderal Index',
        value: '${ponderalIndex.toStringAsFixed(1)} kg/m³',
        iconKey: 'ponderal',
      ));
    }

    if (rows.isEmpty) return fallbackRows;
    return rows;
  }

  static String _prettyLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String categoryForBmi(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obesity';
  }

  ColorCategory get colorCategory {
    final c = category.toLowerCase();
    if (c.contains('under')) return ColorCategory.underweight;
    if (c.contains('normal') || c.contains('healthy')) {
      return ColorCategory.normal;
    }
    if (c.contains('over')) return ColorCategory.overweight;
    if (c.contains('obese') || c.contains('obesity')) {
      return ColorCategory.obesity;
    }
    // fallback by value
    return categoryForBmi(bmi) == 'Underweight'
        ? ColorCategory.underweight
        : categoryForBmi(bmi) == 'Normal'
            ? ColorCategory.normal
            : categoryForBmi(bmi) == 'Overweight'
                ? ColorCategory.overweight
                : ColorCategory.obesity;
  }
}

enum ColorCategory { underweight, normal, overweight, obesity }
