import 'package:get_it/get_it.dart';

import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/identification_repository.dart';
import 'domain/repositories/insights_repository.dart';
import 'domain/repositories/mock/mock_api_client.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/repositories/plant_repository.dart';
import 'domain/repositories/pokedex_repository.dart';
import 'interceptors/api_interceptor.dart';
import 'storage_manager.dart';
import 'stores/app_shell_store.dart';
import 'stores/auth_store.dart';
import 'stores/condition_update_store.dart';
import 'stores/insights_store.dart';
import 'stores/notifications_store.dart';
import 'stores/onboarding_store.dart';
import 'stores/permissions_store.dart';
import 'stores/plant_collection_store.dart';
import 'stores/plant_detail_store.dart';
import 'stores/pokedex_store.dart';
import 'stores/profile_store.dart';
import 'stores/scanning_store.dart';

final GetIt locator = GetIt.instance;

/// Wires storage, the API client, repositories and stores.
///
/// Repositories are registered against their abstract type so a real backend
/// can be dropped in by changing this file alone. [interceptors] lets tests
/// swap out the artificial latency.
Future<void> setupLocator({List<ApiInterceptor>? interceptors}) async {
  final storage = await StorageManager.init();
  locator.registerSingleton<StorageManager>(storage);

  locator.registerSingleton<MockApiClient>(
    MockApiClient(
      interceptors: interceptors ??
          const [LoggingInterceptor(), LatencyInterceptor()],
    ),
  );

  final client = locator<MockApiClient>();

  locator
    ..registerSingleton<AuthRepository>(MockAuthRepository(client))
    ..registerSingleton<PlantRepository>(MockPlantRepository(client))
    ..registerSingleton<PokedexRepository>(MockPokedexRepository(client))
    ..registerSingleton<InsightsRepository>(MockInsightsRepository(client))
    ..registerSingleton<NotificationsRepository>(
        MockNotificationsRepository(client))
    ..registerSingleton<IdentificationRepository>(
        MockIdentificationRepository(client));

  // ── Stores ───────────────────────────────────────────────────────────────
  locator
    ..registerSingleton<AuthStore>(AuthStore(locator<AuthRepository>(), storage))
    ..registerSingleton<OnboardingStore>(OnboardingStore(storage))
    ..registerSingleton<PermissionsStore>(PermissionsStore(storage))
    ..registerSingleton<AppShellStore>(AppShellStore(storage))
    ..registerSingleton<PlantCollectionStore>(
        PlantCollectionStore(locator<PlantRepository>()))
    ..registerSingleton<PokedexStore>(PokedexStore(locator<PokedexRepository>()))
    ..registerSingleton<InsightsStore>(
        InsightsStore(locator<InsightsRepository>()))
    ..registerSingleton<NotificationsStore>(
        NotificationsStore(locator<NotificationsRepository>()));

  locator
    ..registerSingleton<ProfileStore>(
        ProfileStore(locator<AuthStore>(), locator<PlantCollectionStore>()))
    ..registerSingleton<ScanningStore>(ScanningStore(
      locator<IdentificationRepository>(),
      locator<PlantCollectionStore>(),
      locator<PermissionsStore>(),
      client,
    ));

  // One detail store per open plant screen; one flow store per update.
  locator
    ..registerFactory<PlantDetailStore>(() => PlantDetailStore(
          locator<PlantRepository>(),
          locator<PlantCollectionStore>(),
        ))
    ..registerFactory<ConditionUpdateStore>(() => ConditionUpdateStore(
          locator<PlantRepository>(),
          locator<PlantCollectionStore>(),
        ));
}
