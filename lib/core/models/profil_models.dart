/// Miroir de `com.malimall.backend.entity.enums.TypeVehicule`.
enum TypeVehicule { scooter, telimani, tricycle }

extension TypeVehiculeJson on TypeVehicule {
  String get valeurBackend {
    switch (this) {
      case TypeVehicule.scooter:
        return 'SCOOTER';
      case TypeVehicule.telimani:
        return 'TELIMANI';
      case TypeVehicule.tricycle:
        return 'TRICYCLE';
    }
  }

  String get libelle {
    switch (this) {
      case TypeVehicule.scooter:
        return 'Scooter';
      case TypeVehicule.telimani:
        return 'Telimani';
      case TypeVehicule.tricycle:
        return 'TriCycle';
    }
  }
}
