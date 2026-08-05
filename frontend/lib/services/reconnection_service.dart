import 'dart:async';
import 'package:dio/dio.dart';
import 'discovery_service.dart';
import 'storage_service.dart';

class ReconnectionService {
  final StorageService _storageService;
  final Dio _dio;
  static const int _connectivityCheckTimeoutSeconds = 2;

  ReconnectionService({
    StorageService? storageService,
    Dio? dio,
  })  : _storageService = storageService ?? StorageService(),
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Checks if a backend URL is reachable with a short timeout.
  /// Returns true if the server responds, false otherwise.
  Future<bool> isUrlReachable(String url) async {
    try {
      final response = await _dio.get(
        '$url/api/productos',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      ).timeout(const Duration(seconds: _connectivityCheckTimeoutSeconds));

      return response.statusCode != null && response.statusCode! < 500;
    } catch (e) {
      // Timeout, connection refused, DNS error, etc.
      return false;
    }
  }

  /// Attempts to reconnect to the backend:
  /// 1. Checks if the saved URL is reachable
  /// 2. If not, performs mDNS discovery for the saved service name
  /// 3. Updates the URL if a matching service is found
  /// Returns the backend URL to use (saved URL or discovered URL)
  Future<String?> attemptReconnection(String? savedUrl, String? savedServiceName) async {
    // If there's a saved URL, check if it's reachable
    if (savedUrl != null && savedUrl.isNotEmpty) {
      if (await isUrlReachable(savedUrl)) {
        // Saved URL is still reachable, use it
        return savedUrl;
      }
    }

    // If saved URL is not reachable, try mDNS discovery
    try {
      final services = await DiscoveryService.discoverServices(
        timeout: const Duration(seconds: 4),
      );

      if (services.isEmpty) {
        // No services found, return saved URL if available (even if unreachable)
        return savedUrl;
      }

      // If we have a service name, try to find a matching one
      DiscoveredService? selectedService;
      if (savedServiceName != null && savedServiceName.isNotEmpty) {
        selectedService = services.firstWhere(
          (service) => service.name == savedServiceName,
          orElse: () => services.first,
        );
      } else {
        // No service name saved, use the first discovered service
        selectedService = services.first;
      }

      // Build the URL and save it only if valid
      final discoveredUrl = 'http://${selectedService.ip}:${selectedService.port}';
      
      // L6.2: Only save if the discovered URL is valid
      if (discoveredUrl.isNotEmpty) {
        await _storageService.saveBackendUrl(discoveredUrl);
      }
      
      // Save service name only if valid
      if (selectedService.name.isNotEmpty) {
        await _storageService.saveBackendServiceName(selectedService.name);
      }

      return discoveredUrl;
    } catch (e) {
      // mDNS discovery failed, return saved URL if available
      return savedUrl;
    }
  }
}
