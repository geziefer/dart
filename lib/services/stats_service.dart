import 'package:dart/services/storage_service.dart';

/// Service for handling common game statistics operations
class StatsService {
  final StorageService _storageService;
  
  StatsService(this._storageService);
  
  /// Increment the number of games played
  void incrementGameCount() {
    int current = _storageService.read<int>('numberGames', defaultValue: 0)!;
    _storageService.write('numberGames', current + 1);
  }
  
  /// Update a record value if the new value is better
  void updateRecord<T extends Comparable>(String key, T newValue, {bool higherIsBetter = true}) {
    // Read current value, using null as default to detect first-time records
    T? current = _storageService.read<T>(key);
    
    // Always write if this is the first time (current is null)
    if (current == null) {
      _storageService.write(key, newValue);
      return;
    }
    
    // For numeric types, also write if current is 0 (matches old behavior)
    if ((current is num && current == 0) || 
        (higherIsBetter ? newValue.compareTo(current) > 0 : newValue.compareTo(current) < 0)) {
      _storageService.write(key, newValue);
    }
  }
  
  /// Update a record value with custom comparison logic
  void updateRecordWithCondition<T>(String key, T newValue, bool Function(T current, T newValue) shouldUpdate) {
    T? current = _storageService.read<T>(key, defaultValue: newValue);
    if (current != null && shouldUpdate(current, newValue)) {
      _storageService.write(key, newValue);
    } else if (current == null) {
      _storageService.write(key, newValue);
    }
  }
  
  /// Update a long-term average with a new value
  /// Note: This assumes numberGames has already been incremented by incrementGameCount()
  void updateLongTermAverage(String key, double newValue) {
    int newGameCount = _storageService.read<int>('numberGames', defaultValue: 0)!;
    double currentAverage = _storageService.read<double>(key, defaultValue: 0.0)!;
    
    // Since numberGames has already been incremented, we need to use (newGameCount - 1) as the old count
    int oldGameCount = newGameCount - 1;
    
    // Calculate new average: ((old_avg * old_count) + new_value) / new_count
    double updatedAverage = oldGameCount > 0 
        ? ((currentAverage * oldGameCount) + newValue) / newGameCount
        : newValue;
        
    _storageService.write(key, updatedAverage);
  }
  
  /// Get current game statistics
  Map<String, dynamic> getGameStats() {
    return {
      'numberGames': _storageService.read<int>('numberGames', defaultValue: 0)!,
    };
  }
  
  /// Get a specific stat value
  T? getStat<T>(String key, {T? defaultValue}) {
    return _storageService.read<T>(key, defaultValue: defaultValue);
  }
  
  /// Update multiple stats at once
  void updateStats(Map<String, dynamic> stats) {
    stats.forEach((key, value) {
      _storageService.write(key, value);
    });
  }
}
