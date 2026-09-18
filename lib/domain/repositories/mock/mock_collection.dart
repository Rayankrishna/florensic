import 'dart:math';

import '../../../enum.dart';
import '../../models/care_task.dart';
import '../../models/plant.dart';
import '../../models/plant_care_schedule.dart';
import '../../models/plant_condition_update.dart';
import '../../models/plant_health.dart';
import 'mock_species.dart';
import '../../../utils/app_clock.dart';

/// Builds the keeper's seed collection.
///
/// Every date is derived from "today" so the schedule, calendar strip and
/// trend charts stay coherent whenever the app is run.
class MockCollection {
  const MockCollection._();

  static DateTime get _today {
    final n = AppClock.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _days(int d) => _today.add(Duration(days: d));

  static DateTime _at(int dayOffset, int hour, int minute) {
    final d = _days(dayOffset);
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  /// A gently rising series that lands exactly on [score].
  ///
  /// [weekChange] is how much the score has moved over the last seven days, so
  /// the dashboard's `7-day change` stat is consistent with the chart.
  static List<HealthPoint> _history(
    int score, {
    int days = 90,
    int seed = 1,
    int weekChange = 6,
  }) {
    final rnd = Random(seed);
    final points = <HealthPoint>[];
    // Walk backwards from today so the final point is always `score`.
    var value = score.toDouble();
    for (var i = 0; i < days; i++) {
      points.add(HealthPoint(date: _days(-i), score: value.round().clamp(1, 100)));
      value -= i < 7
          ? weekChange / 7 + (rnd.nextDouble() - 0.5) * 2.6
          : rnd.nextDouble() * 1.2 - 0.55;
      value = value.clamp(25, 99);
    }
    return points.reversed.toList(growable: false);
  }

  /// A run of past check-ins, one every [intervalDays], ending [lastAgo] days
  /// ago. Keeps `Updates` and `Condition history` counts in step.
  static List<ConditionUpdate> _updateRun(
    String plantId,
    int count, {
    required int intervalDays,
    required int lastAgo,
    String note = '',
    ConditionVerdict verdict = ConditionVerdict.healthy,
  }) {
    return [
      for (var i = count - 1; i >= 0; i--)
        _update(
          plantId,
          lastAgo + i * intervalDays,
          verdict,
          note: i == 0 ? note : '',
        ),
    ];
  }

  /// A declining series — used for a plant that is losing condition.
  static List<HealthPoint> _decliningHistory(int score,
      {int days = 90, int seed = 7, int weekDrop = 19}) {
    final rnd = Random(seed);
    final points = <HealthPoint>[];
    var value = score.toDouble();
    for (var i = 0; i < days; i++) {
      points.add(HealthPoint(date: _days(-i), score: value.round().clamp(1, 100)));
      // Steep recovery walking backwards over the last week, then flat.
      value += i < 7 ? weekDrop / 7 : rnd.nextDouble() * 1.2 - 0.6;
      value = value.clamp(25, 99);
    }
    return points.reversed.toList(growable: false);
  }

  static CareSchedule _schedule({
    required int nextWaterIn,
    required int lastWateredAgo,
    required int frequencyDays,
    required int amountMl,
    required int checkInIntervalDays,
    required int checkInOpensIn,
  }) {
    return CareSchedule(
      nextWatering: _days(nextWaterIn),
      nextWaterAmountMl: amountMl,
      frequencyDays: frequencyDays,
      lastWatered: _at(-lastWateredAgo, 7, 40),
      lastAmountMl: amountMl - 30,
      checkInIntervalDays: checkInIntervalDays,
      checkInWindowDays: 3,
      checkInWindowOpens: _days(checkInOpensIn),
      wateringReminder: true,
      checkInReminder: true,
      reminderTime: '08:00',
    );
  }

  static ConditionUpdate _update(
    String plantId,
    int daysAgo,
    ConditionVerdict verdict, {
    String note = '',
    List<String> observations = const [],
  }) {
    return ConditionUpdate(
      id: '$plantId-u$daysAgo',
      plantId: plantId,
      takenAt: _at(-daysAgo, 9, 14),
      verdict: verdict,
      observations: observations,
      note: note,
      scoreDelta: verdict.scoreDelta,
    );
  }

  static List<Plant> build() {
    final monstera = Plant(
      id: 'p-monstera',
      species: MockSpecies.byId('monstera-deliciosa'),
      nickname: 'Monstera',
      room: 'Living room',
      indoor: true,
      addedOn: _days(-256),
      healthScore: 82,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: 5,
        lastWateredAgo: 2,
        frequencyDays: 7,
        amountMl: 250,
        checkInIntervalDays: 14,
        checkInOpensIn: 0,
      ),
      history: _history(82, seed: 3),
      updates: _updateRun('p-monstera', 14,
          intervalDays: 14, lastAgo: 12, note: 'New leaf unfurling.'),
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 220 ml',
          detail: 'Morning, before the heat',
          at: _at(-2, 7, 40),
        ),
        CareEvent(
          type: CareEventType.conditionUpdate,
          title: 'Condition update · Looks healthy',
          detail: 'New leaf unfurling',
          at: _at(-12, 9, 14),
        ),
        CareEvent(
          type: CareEventType.repotted,
          title: 'Repotted · 22 cm pot',
          detail: 'Chunky aroid mix',
          at: _at(-67, 11, 0),
        ),
      ],
      photoCount: 14,
      streakWeeks: 9,
      lightStatus: MetricStatus.good,
      lightDetail: 'Bright indirect',
    );

    final peaceLily = Plant(
      id: 'p-peace-lily',
      species: MockSpecies.byId('spathiphyllum-wallisii'),
      nickname: 'Peace Lily',
      room: 'Bedroom',
      indoor: true,
      addedOn: _days(-120),
      healthScore: 74,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: 0,
        lastWateredAgo: 6,
        frequencyDays: 6,
        amountMl: 200,
        checkInIntervalDays: 14,
        checkInOpensIn: 6,
      ),
      history: _history(74, seed: 11, weekChange: 2),
      updates: [
        ..._updateRun('p-peace-lily', 8, intervalDays: 14, lastAgo: 22),
        _update('p-peace-lily', 8, ConditionVerdict.concerns,
            observations: ['Drooping'], note: 'Drooped before I got to it.'),
      ],
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 200 ml',
          detail: 'Recovered within the hour',
          at: _at(-6, 8, 5),
        ),
        CareEvent(
          type: CareEventType.conditionUpdate,
          title: 'Condition update · Some concerns',
          detail: 'Drooping',
          at: _at(-8, 9, 20),
        ),
      ],
      photoCount: 9,
      streakWeeks: 6,
      lightStatus: MetricStatus.good,
      lightDetail: 'Medium indirect',
    );

    final snakePlant = Plant(
      id: 'p-snake-plant',
      species: MockSpecies.byId('dracaena-trifasciata'),
      nickname: 'Snake Plant',
      room: 'Hallway',
      indoor: true,
      addedOn: _days(-410),
      healthScore: 91,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: 9,
        lastWateredAgo: 0,
        frequencyDays: 18,
        amountMl: 180,
        checkInIntervalDays: 21,
        checkInOpensIn: 11,
      ),
      history: _history(91, seed: 5, weekChange: 3),
      updates: _updateRun('p-snake-plant', 11,
          intervalDays: 21, lastAgo: 13),
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 180 ml',
          detail: 'First drink in three weeks',
          at: _at(0, 7, 40),
        ),
      ],
      photoCount: 11,
      streakWeeks: 14,
      lightStatus: MetricStatus.good,
      lightDetail: 'Low, tolerates it well',
    );

    final fiddleLeaf = Plant(
      id: 'p-fiddle-leaf',
      species: MockSpecies.byId('ficus-lyrata'),
      nickname: 'Fiddle Leaf Fig',
      room: 'Study',
      indoor: true,
      addedOn: _days(-67),
      healthScore: 68,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: -4,
        lastWateredAgo: 14,
        frequencyDays: 10,
        amountMl: 320,
        checkInIntervalDays: 14,
        checkInOpensIn: 4,
      ),
      history: _decliningHistory(68, seed: 17),
      updates: [
        ..._updateRun('p-fiddle-leaf', 9, intervalDays: 14, lastAgo: 33),
        _update('p-fiddle-leaf', 19, ConditionVerdict.concerns,
            observations: ['Leaf damage']),
        _update('p-fiddle-leaf', 5, ConditionVerdict.needsAttention,
            observations: ['Leaf damage', 'Drooping'],
            note: 'Two leaves dropped after I moved it.'),
      ],
      careHistory: [
        CareEvent(
          type: CareEventType.moved,
          title: 'Moved · window bay',
          detail: 'Afternoon sun reaches it now',
          at: _at(-21, 16, 30),
        ),
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 320 ml',
          detail: 'Ran clear from the base',
          at: _at(-14, 7, 40),
        ),
      ],
      photoCount: 11,
      streakWeeks: 3,
      lightStatus: MetricStatus.watch,
      lightDetail: 'Afternoon sun',
      leafDropReported: true,
    );

    final aloe = Plant(
      id: 'p-aloe-vera',
      species: MockSpecies.byId('aloe-barbadensis'),
      nickname: 'Aloe Vera',
      room: 'Balcony',
      indoor: false,
      addedOn: _days(-190),
      healthScore: 88,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: 0,
        lastWateredAgo: 14,
        frequencyDays: 14,
        amountMl: 150,
        checkInIntervalDays: 21,
        checkInOpensIn: 8,
      ),
      history: _history(88, seed: 23, weekChange: 2),
      updates: _updateRun('p-aloe-vera', 7, intervalDays: 21, lastAgo: 16),
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 150 ml',
          detail: 'Soaked, then drained fully',
          at: _at(-14, 7, 10),
        ),
      ],
      photoCount: 7,
      streakWeeks: 11,
      lightStatus: MetricStatus.good,
      lightDetail: 'Direct morning sun',
    );

    final pothos = Plant(
      id: 'p-golden-pothos',
      species: MockSpecies.byId('epipremnum-aureum'),
      nickname: 'Golden Pothos',
      room: 'Kitchen',
      indoor: true,
      addedOn: _days(-300),
      healthScore: 79,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: 4,
        lastWateredAgo: 5,
        frequencyDays: 9,
        amountMl: 190,
        checkInIntervalDays: 14,
        checkInOpensIn: 5,
      ),
      history: _history(79, seed: 31, weekChange: 4),
      updates: _updateRun('p-golden-pothos', 12,
          intervalDays: 14, lastAgo: 9),
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 190 ml',
          detail: 'Trimmed two long vines',
          at: _at(-5, 8, 0),
        ),
      ],
      photoCount: 12,
      streakWeeks: 8,
      lightStatus: MetricStatus.good,
      lightDetail: 'Bright indirect',
    );

    final parlourPalm = Plant(
      id: 'p-parlour-palm',
      species: MockSpecies.byId('chamaedorea-elegans'),
      nickname: 'Parlour Palm',
      room: 'Landing',
      indoor: true,
      addedOn: _days(-220),
      healthScore: null,
      careStatus: CareStatus.paused,
      schedule: _schedule(
        nextWaterIn: 3,
        lastWateredAgo: 6,
        frequencyDays: 9,
        amountMl: 210,
        checkInIntervalDays: 14,
        checkInOpensIn: -38,
      ),
      history: const [],
      updates: _updateRun('p-parlour-palm', 11,
          intervalDays: 14, lastAgo: 52),
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 210 ml',
          detail: 'Reminders still running',
          at: _at(-6, 8, 0),
        ),
      ],
      photoCount: 11,
      streakWeeks: 0,
      lightStatus: MetricStatus.neutral,
      lightDetail: 'Low, north-facing',
    );

    final quiet = <_Quiet>[
      const _Quiet('p-zz-plant', 'zamioculcas-zamiifolia', 'ZZ Plant', 'Hallway', 93,
          16, 19, 41),
      const _Quiet('p-calathea', 'goeppertia-orbifolia', 'Calathea Orbifolia',
          'Bathroom', 71, 3, 6, 43),
      const _Quiet('p-rubber-plant', 'ficus-elastica', 'Rubber Plant', 'Living room',
          86, 7, 10, 47),
      const _Quiet('p-spider-plant', 'chlorophytum-comosum', 'Spider Plant', 'Kitchen',
          84, 5, 7, 53),
      const _Quiet('p-philodendron', 'philodendron-hederaceum', 'Philodendron Brasil',
          'Study', 89, 6, 8, 59),
    ];

    return [
      monstera,
      peaceLily,
      snakePlant,
      fiddleLeaf,
      aloe,
      pothos,
      parlourPalm,
      ...quiet.map(_buildQuiet),
    ];
  }

  static Plant _buildQuiet(_Quiet q) {
    final species = MockSpecies.byId(q.speciesId);
    return Plant(
      id: q.id,
      species: species,
      nickname: q.name,
      room: q.room,
      indoor: true,
      addedOn: _days(-140 - q.seed),
      healthScore: q.score,
      careStatus: CareStatus.active,
      schedule: _schedule(
        nextWaterIn: q.nextWaterIn,
        lastWateredAgo: q.frequency - q.nextWaterIn,
        frequencyDays: q.frequency,
        amountMl: 200,
        checkInIntervalDays: 14,
        checkInOpensIn: 2 + (q.seed % 9),
      ),
      history: _history(q.score, seed: q.seed, weekChange: 1 + q.seed % 4),
      updates: _updateRun(q.id, 4 + (q.seed % 6),
          intervalDays: 14, lastAgo: 5 + (q.seed % 7)),
      careHistory: [
        CareEvent(
          type: CareEventType.watered,
          title: 'Watered · 200 ml',
          detail: q.room,
          at: _at(-(q.frequency - q.nextWaterIn), 8, 0),
        ),
      ],
      photoCount: 4 + (q.seed % 6),
      streakWeeks: 4 + (q.seed % 8),
      lightStatus: MetricStatus.good,
      lightDetail: species.light,
    );
  }

  /// Today's care list on the home dashboard.
  static List<CareTask> tasks(List<Plant> plants) {
    final list = <CareTask>[];
    for (final p in plants) {
      if (p.paused) continue;
      if (p.conditionDue) {
        list.add(CareTask(
          id: 'task-cond-${p.id}',
          plantId: p.id,
          title: 'Condition update · ${p.nickname}',
          detail: p.conditionOverdueDays > 0
              ? 'Overdue by ${p.conditionOverdueDays} day'
                  '${p.conditionOverdueDays == 1 ? '' : 's'}'
              : 'Due today · keeps care status active',
          kind: MetricKind.condition,
          overdue: p.conditionOverdueDays > 0,
        ));
      }
      if (p.waterDue) {
        final overdue = p.daysUntilWatering < 0;
        list.add(CareTask(
          id: 'task-water-${p.id}',
          plantId: p.id,
          title: 'Water the ${p.nickname}',
          detail: overdue
              ? 'Overdue by ${-p.daysUntilWatering} days · ${p.room}'
              : 'Due today · ${p.room}',
          kind: MetricKind.watering,
          overdue: overdue,
        ));
      }
      if (p.daysSinceWatered == 0 && !p.waterDue) {
        list.add(CareTask(
          id: 'task-water-${p.id}',
          plantId: p.id,
          title: 'Water the ${p.nickname}',
          detail: 'Done · 7:40',
          kind: MetricKind.watering,
          overdue: false,
          done: true,
          doneAt: '7:40',
        ));
      }
    }
    return list;
  }
}

class _Quiet {
  const _Quiet(this.id, this.speciesId, this.name, this.room, this.score,
      this.nextWaterIn, this.frequency, this.seed);

  final String id;
  final String speciesId;
  final String name;
  final String room;
  final int score;
  final int nextWaterIn;
  final int frequency;
  final int seed;
}
