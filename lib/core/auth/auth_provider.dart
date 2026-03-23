import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../api/api_client.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authStateProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  final pkgInfo = await PackageInfo.fromPlatform();
  await storage.cancellaSeMismatchVersione(pkgInfo.version);
  return storage.haCredenziali();
});

final apiClientProvider = FutureProvider<ApiClient?>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  final url = await storage.getUrl();
  final token = await storage.getToken();
  if (url == null || token == null) return null;
  return ApiClient(baseUrl: url, token: token);
});
