/// Thông báo lỗi thân thiện (tiếng Việt) cho UI.
abstract final class ErrorMessages {
  static String forUser(Object error) {
    final raw = _stripPrefix('$error').toLowerCase();

    if (_looksOffline(raw)) {
      return 'Không có kết nối mạng. Kiểm tra Wi‑Fi/4G rồi thử lại.';
    }
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'Kết nối quá chậm hoặc hết thời gian chờ. Thử lại sau.';
    }
    if (raw.contains('permission') || raw.contains('permission-denied')) {
      return 'Không có quyền truy cập dữ liệu. Thử lại sau.';
    }
    if (raw.contains('unavailable') || raw.contains('firestore')) {
      return 'Không kết nối được máy chủ. Thử lại sau.';
    }

    final cleaned = _stripPrefix('$error');
    if (cleaned.isEmpty) {
      return 'Đã xảy ra lỗi. Thử lại sau.';
    }
    return cleaned.length > 180 ? '${cleaned.substring(0, 180)}…' : cleaned;
  }

  static bool _looksOffline(String raw) {
    return raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network is unreachable') ||
        raw.contains('connection refused') ||
        raw.contains('connection reset') ||
        raw.contains('clientexception') ||
        raw.contains('không kết nối') ||
        raw.contains('offline') ||
        raw.contains('no address associated');
  }

  static String _stripPrefix(String message) {
    var text = message.trim();
    const prefixes = [
      'Bad state: ',
      'FormatException: ',
      'Exception: ',
      'StateError: ',
    ];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length);
        break;
      }
    }
    return text.trim();
  }
}
