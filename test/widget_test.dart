import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plant_gram/enum.dart';
import 'package:plant_gram/domain/repositories/pokedex_repository.dart';
import 'package:plant_gram/locator.dart';
import 'package:plant_gram/routes.dart';
import 'package:plant_gram/stores/condition_update_store.dart';
import 'package:plant_gram/stores/plant_collection_store.dart';
import 'package:plant_gram/theme.dart';

import 'support/harness.dart';

void main() {
  group('routing', () {
    testWidgets('unknown routes fall back to a recoverable screen',
        (tester) async {
      final route = AppRoutes.onGenerateRoute(
        const RouteSettings(name: '/not-a-real-route'),
      ) as PageRouteBuilder<dynamic>;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Builder(
            builder: (context) => route.buildPage(
              context,
              const AlwaysStoppedAnimation<double>(1),
              const AlwaysStoppedAnimation<double>(0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('That screen has moved'), findsOneWidget);
    });
  });

  group('stores', () {
    setUp(() => Harness.bootstrap());

    test('the collection loads and watering reschedules the plant', () async {
      final collection = locator<PlantCollectionStore>();
      await collection.loadPlants();

      expect(collection.plants, hasLength(12));
      expect(collection.attentionCount, greaterThan(0));

      final before = collection.plantById('p-peace-lily')!;
      expect(before.waterDue, isTrue);

      final after = await collection.markAsWatered('p-peace-lily');
      expect(after, isNotNull);
      expect(after!.waterDue, isFalse);
      expect(after.daysUntilWatering, after.schedule.frequencyDays);
    });

    test('a saved condition update moves the score and keeps care active',
        () async {
      final collection = locator<PlantCollectionStore>();
      await collection.loadPlants();
      final monstera = collection.plantById('p-monstera')!;
      final scoreBefore = monstera.healthScore!;
      final updatesBefore = monstera.updates.length;

      final flow = locator<ConditionUpdateStore>()..start(monstera);
      await flow.capture();
      expect(flow.step, 1);

      flow
        ..next()
        ..setVerdict(ConditionVerdict.healthy)
        ..toggleObservation('Slow growth')
        ..setNote('New leaf on the way.');
      final saved = await flow.save();

      expect(saved, isTrue);
      expect(flow.newScore, scoreBefore + ConditionVerdict.healthy.scoreDelta);
      final refreshed = collection.plantById('p-monstera')!;
      expect(refreshed.updates.length, updatesBefore + 1);
      expect(refreshed.conditionDue, isFalse);
      expect(refreshed.careStatus, CareStatus.active);
    });

    test('an added plant keeps the keeper\'s nickname', () async {
      final collection = locator<PlantCollectionStore>();
      await collection.loadPlants();
      final species = locator<PokedexRepository>().plantOfTheWeek;

      final named = await collection.addPlant(species, nickname: '  Steve  ');
      expect(named!.nickname, 'Steve');
      expect(named.latinName, species.latinName);

      final unnamed = await collection.addPlant(species, nickname: '   ');
      expect(unnamed!.nickname, species.commonName);

      final omitted = await collection.addPlant(species);
      expect(omitted!.nickname, species.commonName);
    });

    test('a paused plant resumes active care with a fresh baseline', () async {
      final collection = locator<PlantCollectionStore>();
      await collection.loadPlants();
      final palm = collection.plantById('p-parlour-palm')!;
      expect(palm.paused, isTrue);
      expect(palm.healthScore, isNull);

      final flow = locator<ConditionUpdateStore>()..start(palm);
      flow.setVerdict(ConditionVerdict.healthy);
      await flow.save();

      final resumed = collection.plantById('p-parlour-palm')!;
      expect(resumed.careStatus, CareStatus.active);
      expect(resumed.healthScore, isNotNull);
    });
  });
}
