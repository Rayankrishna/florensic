import 'package:mobx/mobx.dart';

import '../domain/models/user_profile.dart';
import 'auth_store.dart';
import 'plant_collection_store.dart';

part 'profile_store.g.dart';

class ProfileStore = _ProfileStore with _$ProfileStore;

abstract class _ProfileStore with Store {
  _ProfileStore(this._auth, this._collection);

  final AuthStore _auth;
  final PlantCollectionStore _collection;

  @computed
  UserProfile? get profile => _auth.profile;

  /// Empty until the profile has loaded — there is no stand-in account.
  @computed
  String get name => profile?.name ?? '';

  @computed
  String get email => profile?.email ?? '';

  @computed
  String get initial => profile?.initial ?? '?';

  /// Live counts, so the profile reflects what the collection actually holds.
  @computed
  int get plantsKept => _collection.plants.length;

  @computed
  int get underActiveCare => _collection.underActiveCare;

  /// Null until a plant under care has been scored.
  @computed
  int? get averageHealth => _collection.averageHealth;

  @computed
  int get careStreakWeeks => profile?.careStreakWeeks ?? 0;

  @action
  Future<void> signOut() async {
    await _auth.signOut();
    _collection.clear();
  }
}
