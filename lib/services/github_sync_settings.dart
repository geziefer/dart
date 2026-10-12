import 'package:dart/services/storage_service.dart';

/// Local-only storage for GitHub sync credentials (Personal Access Token).
///
/// The PAT is entered by the user at runtime (once per device) and stored
/// locally in get_storage. It is NEVER committed to source control.
class GitHubSyncSettings {
  static const String containerName = 'github_sync';
  static const String _keyToken = 'pat';

  final StorageService _storage;

  GitHubSyncSettings({StorageService? storage})
      : _storage = storage ?? StorageService(containerName);

  String get token =>
      _storage.read<String>(_keyToken, defaultValue: '') ?? '';

  bool get isConfigured => token.isNotEmpty;

  void save(String token) {
    _storage.write<String>(_keyToken, token.trim());
  }

  void clear() {
    _storage.write<String>(_keyToken, '');
  }
}
