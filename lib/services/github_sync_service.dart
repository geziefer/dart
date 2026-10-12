import 'dart:convert';

import 'package:github/github.dart';

import 'package:dart/services/github_sync_settings.dart';

/// Fixed repository and file path for the stats sync.
const String _repoOwner = 'geziefer';
const String _repoName = 'dart-stats';
const String _filePath = 'dart_stats.json';

/// Result of a sync read operation.
class SyncReadResult {
  /// The file content (JSON string), or null if the file doesn't exist yet.
  final String? content;

  /// The blob SHA of the remote file (needed for updates). Null if not found.
  final String? sha;

  const SyncReadResult({this.content, this.sha});
}

/// Reads and writes the stats JSON to a private GitHub repo via the Contents
/// API. Uses a Personal Access Token (PAT) stored locally per device.
///
/// This is a thin wrapper: the sync logic (timestamps, when to pull/push) lives
/// elsewhere; this service only does the raw file I/O against GitHub.
class GitHubSyncService {
  final GitHubSyncSettings _settings;

  GitHubSyncService(this._settings);

  GitHub _client() => GitHub(
        auth: Authentication.withToken(_settings.token),
      );

  RepositorySlug get _slug => RepositorySlug(_repoOwner, _repoName);

  /// Read the current `dart_stats.json` from the repo. Returns content + SHA,
  /// or null content + null SHA if the file doesn't exist yet (empty repo).
  Future<SyncReadResult> read() async {
    final gh = _client();
    try {
      final contents = await gh.repositories.getContents(
        _slug,
        _filePath,
      );
      // getContents returns a RepositoryContents; the file content is
      // base64-encoded in `contents.file.content`.
      final file = contents.file;
      if (file == null) return const SyncReadResult();
      final decoded = utf8.decode(base64.decode(
          file.content?.replaceAll('\n', '') ?? ''));
      return SyncReadResult(content: decoded, sha: file.sha);
    } on NotFound {
      return const SyncReadResult(); // file not yet created
    } finally {
      gh.dispose();
    }
  }

  /// Write [jsonContent] to `dart_stats.json`. If [sha] is provided, updates
  /// the existing file (optimistic lock — fails if the remote SHA changed);
  /// if null, creates the file.
  ///
  /// Returns the new SHA on success, or throws on failure.
  Future<String> write(String jsonContent, {String? sha}) async {
    final gh = _client();
    final content = base64.encode(utf8.encode(jsonContent));
    try {
      final ContentCreation result;
      if (sha == null) {
        result = await gh.repositories.createFile(
          _slug,
          CreateFile(
            path: _filePath,
            content: content,
            message: 'sync',
            branch: 'main',
          ),
        );
      } else {
        result = await gh.repositories.updateFile(
          _slug,
          _filePath,
          'sync',
          content,
          sha,
          branch: 'main',
        );
      }
      return result.content?.sha ?? '';
    } finally {
      gh.dispose();
    }
  }
}
