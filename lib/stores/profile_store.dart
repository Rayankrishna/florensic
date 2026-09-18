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

  @computed
  String get name => profile?.name ?? 'Alex Moreau';

  @computed
  String get email => profile?.email ?? 'alex.moreau@studio.co';

  @computed
  String get initial => profile?.initial ?? 'A';

  @computed
  String get city => profile?.city ?? 'Mumbai';

  /// Live counts, so the profile reflects what the collection actually holds.
  @computed
  int get plantsKept => _collection.plants.length;

  @computed
  int get underActiveCare => _collection.underActiveCare;

  @computed
  int get averageHealth => _collection.averageHealth;

  @computed
  int get careStreakWeeks => profile?.careStreakWeeks ?? 32;

  @computed
  String get streakSince => profile?.streakSince ?? 'February';

  @computed
  String get reminderTime => profile?.reminderTime ?? '08:00';

  @computed
  String get units => profile?.units ?? '°C · ml';

  @action
  Future<void> signOut() async {
    await _auth.signOut();
    _collection.clear();
  }
}
