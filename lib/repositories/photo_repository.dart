import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

abstract class PhotoRepository {
  Future<Uint8List?> downloadPhoto(String photoId);
  Future<bool> uploadPhoto(String photoId, Uint8List imageBytes, {String contentType = 'image/jpeg'});
}

class PhotoRepositoryImpl implements PhotoRepository {
  final ApiClient apiClient;

  PhotoRepositoryImpl({required this.apiClient});

  @override
  Future<Uint8List?> downloadPhoto(String photoId) async {
    try {
      final response = await apiClient.get<List<int>>(
        '${ApiConstants.photosEndpoint}/$photoId',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (_) {
      // Photo download failed or offline
    }
    return null;
  }

  @override
  Future<bool> uploadPhoto(
    String photoId,
    Uint8List imageBytes, {
    String contentType = 'image/jpeg',
  }) async {
    try {
      final response = await apiClient.put(
        '${ApiConstants.photosEndpoint}/$photoId',
        data: Stream.fromIterable([imageBytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': imageBytes.length,
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
