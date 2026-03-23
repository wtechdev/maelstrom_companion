/// Restituisce true se [latest] è una versione maggiore di [installed].
/// Ignora i tag pre-release (es. "1.1.0-beta").
bool isNewerVersion(String installed, String latest) {
  if (latest.contains('-')) return false;

  final a = installed.split('.').map(int.parse).toList();
  final b = latest.split('.').map(int.parse).toList();

  for (var i = 0; i < b.length; i++) {
    final ai = i < a.length ? a[i] : 0;
    if (b[i] > ai) return true;
    if (b[i] < ai) return false;
  }
  return false;
}
