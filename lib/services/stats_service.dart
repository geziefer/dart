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
    T? current = _storageService.read<T>(key, defaultValue: newValue);
    if (current == null) {
      _storageService.write(key, newValue);
      return;
    }
    
    bool shouldUpdate = higherIsBetter 
        ? newValue.compareTo(current) > 0 
        : newValue.compareTo(current) < 0;
        
    if (shouldUpdate) {
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
  void updateLongTermAverage(String key, double newValue) {
    int gameCount = _storageService.read<int>('numberGames', defaultValue: 0)!;
    double currentAverage = _storageService.read<double>(key, defaultValue: 0.0)!;
    
    // Calculate new average: ((old_avg * old_count) + new_value) / new_count
    double updatedAverage = gameCount > 0 
        ? ((currentAverage * gameCount) + newValue) / (gameCount + 1)
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
