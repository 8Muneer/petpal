import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class SitterAvailabilityState {
  final bool isAvailable;
  final List<bool> availableDays;
  final Map<String, bool> serviceAvailability;
  final Map<String, bool> dateOverrides;
  final bool isLoading;
  final bool isSaving;

  SitterAvailabilityState({
    this.isAvailable = true,
    this.availableDays = const [true, true, true, true, true, false, false],
    this.serviceAvailability = const {'walking': true, 'sitting': true},
    this.dateOverrides = const {},
    this.isLoading = true,
    this.isSaving = false,
  });

  SitterAvailabilityState copyWith({
    bool? isAvailable,
    List<bool>? availableDays,
    Map<String, bool>? serviceAvailability,
    Map<String, bool>? dateOverrides,
    bool? isLoading,
    bool? isSaving,
  }) {
    return SitterAvailabilityState(
      isAvailable: isAvailable ?? this.isAvailable,
      availableDays: availableDays ?? this.availableDays,
      serviceAvailability: serviceAvailability ?? this.serviceAvailability,
      dateOverrides: dateOverrides ?? this.dateOverrides,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class SitterAvailabilityNotifier extends StateNotifier<SitterAvailabilityState> {
  SitterAvailabilityNotifier() : super(SitterAvailabilityState()) {
    load();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  final _db = FirebaseFirestore.instance;

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
      final data = doc.data();

      if (data != null) {
        final List<bool> savedDays = List<bool>.from(
          (data['availableDays'] as List<dynamic>? ?? state.availableDays)
              .map((v) => v == true),
        );
        
        final Map<String, bool> savedServices = Map<String, bool>.from(
          data['serviceAvailability'] as Map<String, dynamic>? ?? state.serviceAvailability,
        );

        final Map<String, bool> savedOverrides = Map<String, bool>.from(
          data['dateOverrides'] as Map<String, dynamic>? ?? state.dateOverrides,
        );

        state = state.copyWith(
          isAvailable: data['isAvailable'] as bool? ?? true,
          availableDays: savedDays,
          serviceAvailability: savedServices,
          dateOverrides: savedOverrides,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleGlobal(bool value) {
    state = state.copyWith(isAvailable: value);
  }

  void toggleDay(int index) {
    final newDays = List<bool>.from(state.availableDays);
    newDays[index] = !newDays[index];
    state = state.copyWith(availableDays: newDays);
  }

  void toggleService(String key) {
    final newServices = Map<String, bool>.from(state.serviceAvailability);
    newServices[key] = !(newServices[key] ?? false);
    state = state.copyWith(serviceAvailability: newServices);
  }

  void toggleDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final newOverrides = Map<String, bool>.from(state.dateOverrides);
    
    // If it's already in overrides, flip it. 
    // If not, we determine its "default" state from availableDays and set the opposite.
    if (newOverrides.containsKey(dateKey)) {
      newOverrides.remove(dateKey);
    } else {
      final bool isNormallyAvailable = state.availableDays[date.weekday % 7];
      newOverrides[dateKey] = !isNormallyAvailable;
    }
    
    state = state.copyWith(dateOverrides: newOverrides);
  }

  bool isDateAvailable(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    if (state.dateOverrides.containsKey(dateKey)) {
      return state.dateOverrides[dateKey]!;
    }
    // Sunday in availableDays is index 0 (matching AvailabilityScreen logic)
    // DateTime.weekday: 1 (Mon) to 7 (Sun)
    // Map to 0-indexed where 0 is Sun
    final weekdayIndex = date.weekday == 7 ? 0 : date.weekday;
    return state.availableDays[weekdayIndex];
  }

  Future<bool> save() async {
    final uid = _uid;
    if (uid == null) return false;

    state = state.copyWith(isSaving: true);
    try {
      await _db.collection(AppConstants.usersCollection).doc(uid).update({
        'isAvailable': state.isAvailable,
        'availableDays': state.availableDays,
        'serviceAvailability': state.serviceAvailability,
        'dateOverrides': state.dateOverrides,
      });
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return false;
    }
  }
}

final sitterAvailabilityProvider =
    StateNotifierProvider<SitterAvailabilityNotifier, SitterAvailabilityState>((ref) {
  return SitterAvailabilityNotifier();
});
