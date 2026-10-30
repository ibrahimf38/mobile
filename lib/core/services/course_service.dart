import '../api/api_client.dart';
import '../models/course_models.dart';

/// Miroir côté client de `CourseController` (backend) — module MotoTaxi.
class CourseService {
  final ApiClient _client;

  CourseService(this._client);

  CourseResponse _course(dynamic json) =>
      CourseResponse.fromJson(json as Map<String, dynamic>);
  List<CourseResponse> _courses(dynamic json) => (json as List)
      .map((e) => CourseResponse.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<String>> quartiers() {
    return _client.get(
        '/api/courses/quartiers', (json) => (json as List).cast<String>());
  }

  Future<EstimationCourse> estimer(
      String depart, String destination, TypeVehicule typeVehicule) {
    return _client.post(
      '/api/courses/estimation',
      (json) => EstimationCourse.fromJson(json as Map<String, dynamic>),
      body: {
        'depart': depart,
        'destination': destination,
        'typeVehicule': typeVehicule.code
      },
    );
  }

  Future<List<ChauffeurDisponible>> chauffeursDisponibles() {
    return _client.get(
      '/api/courses/chauffeurs-disponibles',
      (json) => (json as List)
          .map((e) => ChauffeurDisponible.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<CourseResponse> demander(
      String depart, String destination, TypeVehicule typeVehicule) {
    return _client.post(
      '/api/courses',
      _course,
      body: {
        'depart': depart,
        'destination': destination,
        'typeVehicule': typeVehicule.code
      },
    );
  }

  /// role : 'client' (défaut) ou 'chauffeur'.
  Future<List<CourseResponse>> mesCourses({String role = 'client'}) {
    return _client.get('/api/courses?role=$role', _courses);
  }

  Future<List<CourseResponse>> disponibles() =>
      _client.get('/api/courses/disponibles', _courses);

  Future<CourseResponse> obtenir(int id) =>
      _client.get('/api/courses/$id', _course);

  Future<CourseResponse> accepter(int id) =>
      _client.post('/api/courses/$id/accepter', _course);

  Future<CourseResponse> prendreEnCharge(int id) =>
      _client.post('/api/courses/$id/prise-en-charge', _course);

  Future<CourseResponse> signalerArrivee(int id) =>
      _client.post('/api/courses/$id/signaler-arrivee', _course);

  Future<CourseResponse> confirmerArrivee(int id) =>
      _client.post('/api/courses/$id/confirmer-arrivee', _course);
  Future<CourseResponse> annuler(int id) =>
      _client.post('/api/courses/$id/annuler', _course);

  Future<CourseResponse> noter(int id, int note, String? commentaire) {
    return _client.post('/api/courses/$id/noter', _course,
        body: {'note': note, 'commentaire': commentaire});
  }
}
