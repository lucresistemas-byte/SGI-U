import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';

/// Simple DTO representing a discovered backend service
class DiscoveredService {
  final String name;
  final String ip;
  final int port;

  DiscoveredService({required this.name, required this.ip, required this.port});
}

class DiscoveryService {
  /// Type mDNS que anuncia el backend SGI-U.
  static const String serviceType = '_sgiu._tcp.local';

  /// Discover services of type _sgiu._tcp.local. Returns an empty list on none.
  /// Uses MDnsClient and listens for [timeout] duration. Errors are caught
  /// and do not throw to the caller (keeps the app stable).
  /// Default timeout is 3 seconds to avoid blocking app startup (C.3.4).
  static Future<List<DiscoveredService>> discoverServices({Duration timeout = const Duration(seconds: 3)}) async {
    final List<DiscoveredService> results = [];
    final MDnsClient client = MDnsClient();
    try {
      await client.start();

      // Listen for PTR records that advertise the service
      final ptrStream = client.lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(serviceType));

      // Subscriptions for nested lookups
      final List<StreamSubscription> subscriptions = [];

      final ptrSub = ptrStream.listen((PtrResourceRecord ptr) {
        // For each PTR, resolve SRV records to get target and port
        final srvStream = client.lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName));
        final srvSub = srvStream.listen((SrvResourceRecord srv) {
          // Resolve A (IPv4) records for the SRV target
          final addrStream = client.lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(srv.target));
          final addrSub = addrStream.listen((IPAddressResourceRecord addr) {
            try {
              final ip = addr.address.address;
              final port = srv.port;
              final name = ptr.domainName;
              results.add(DiscoveredService(name: name, ip: ip, port: port));
            } catch (_) {
              // ignore malformed records
            }
          }, onError: (_) {});

          subscriptions.add(addrSub);
        }, onError: (_) {});

        subscriptions.add(srvSub);
      }, onError: (_) {});

      subscriptions.add(ptrSub);

      // Wait for the timeout, then cancel subscriptions and stop the client
      await Future.delayed(timeout);

      for (final sub in subscriptions) {
        try {
          await sub.cancel();
        } catch (_) {}
      }

      try {
        // client.stop() may be synchronous in some versions; call without awaiting
        client.stop();
      } catch (_) {}
    } catch (e) {
      // swallow errors: discovery should not crash the app
    }

    // Deduplicate by ip:port and return
    final seen = <String>{};
    final deduped = <DiscoveredService>[];
    for (final s in results) {
      final key = '${s.ip}:${s.port}';
      if (!seen.contains(key)) {
        seen.add(key);
        deduped.add(s);
      }
    }

    return deduped;
  }
}
