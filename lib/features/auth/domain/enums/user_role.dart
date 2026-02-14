enum UserRole {
  petOwner,
  serviceProvider;

  String get firestoreValue {
    switch (this) {
      case UserRole.petOwner:
        return 'petOwner';
      case UserRole.serviceProvider:
        return 'serviceProvider';
    }
  }

  static UserRole? fromString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final lower = value.trim().toLowerCase();
    switch (lower) {
      case 'petowner':
      case 'pet_owner':
        return UserRole.petOwner;
      case 'serviceprovider':
      case 'service_provider':
      case 'provider':
        return UserRole.serviceProvider;
      default:
        return null;
    }
  }
}
