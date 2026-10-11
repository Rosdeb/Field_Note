class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
  });
}

class LocationService {
  Future<LocationData?> getCurrentLocation() async {
    // TODO: Implement GPS location retrieval
    return null;
  }
}
