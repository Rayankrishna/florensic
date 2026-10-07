import 'package:get_it/get_it.dart';

import 'domain/core/services_config.dart';
import 'domain/core/token_store.dart';
import 'domain/provider/auth.provider.dart';
import 'domain/provider/photos.provider.dart';
import 'domain/repositories/identification_repository.dart';
import 'domain/repositories/insights_repository.dart';
import 'domain/repositories/notifications_repository.dart';
import 'domain/repositories/plant_repository.dart';
import 'domain/repositories/pokedex_repository.dart';
import 'domain/repositories/remote/remote_identification_repository.dart';
import 'domain/repositories/remote/remote_insights_repository.dart';
import 'domain/repositories/remote/remote_plant_repository.dart';
import 'domain/repositories/remote/remote_pokedex_repository.dart';
import 'shared/services/capture_service.dart';
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

/// The repositories the app runs on.
///
/// Production builds the API-backed set; tests pass their own fakes, which is
/// the only reason this is a parameter rather than a constant.
class RepositoryBundle {
  const RepositoryBundle({
    required this.plants,
    required this.pokedex,
    required this.insights,
    required this.identification,
    required this.notifications,
    required this.capture,
  });

  /// The live set, talking to the Florensic API. Auth has no repository:
  /// the store calls [AuthProvider] directly, as in the lead app.
  factory RepositoryBundle.remote() => RepositoryBundle(
        plants: RemotePlantRepository(),
        pokedex: RemotePokedexRepository(),
        insights: RemoteInsightsRepository(),
        identification: RemoteIdentificationRepository(),
        // No notifications endpoint yet — the screen shows its empty state.
        notifications: const UnavailableNotificationsRepository(),
        capture: CaptureService(),
      );

  final PlantRepository plants;
  final PokedexRepository pokedex;
  final InsightsRepository insights;
  final IdentificationRepository identification;
  final NotificationsRepository notifications;
  final CaptureService capture;
}

/// Wires storage, the API client, providers, repositories and stores.
///
/// [repositories] lets tests substitute fakes. Everything else runs against
/// the API; the client logs every call in debug builds.
Future<void> setupLocator({
  RepositoryBundle Function()? repositories,
}) async {
  final storage = await StorageManager.init();
  final tokens = TokenStore();

  locator
    ..registerSingleton<StorageManager>(storage)
    ..registerSingleton<TokenStore>(tokens);

  HttpClient.init(tokens: tokens);

  final bundle = (repositories ?? RepositoryBundle.remote)();

  locator
    ..registerSingleton<AuthProvider>(const AuthProvider())
    ..registerSingleton<CaptureService>(bundle.capture)
    ..registerSingleton<PlantRepository>(bundle.plants)
    ..registerSingleton<PokedexRepository>(bundle.pokedex)
    ..registerSingleton<InsightsRepository>(bundle.insights)
    ..registerSingleton<IdentificationRepository>(bundle.identification)
    ..registerSingleton<NotificationsRepository>(bundle.notifications);

  _registerStores(storage);

  // End a dead session cleanly rather than leaving the user on a screen
  // whose every call 401s.
  http?.onSessionExpired = () => locator<AuthStore>().handleSessionExpired();
}

void _registerStores(StorageManager storage) {
  locator
    ..registerSingleton<AuthStore>(AuthStore(
      locator<AuthProvider>(),
      locator<TokenStore>(),
      storage,
    ))
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
      locator<CaptureService>(),
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
          locator<CaptureService>(),
          const PhotosProvider(),
        ));
}
