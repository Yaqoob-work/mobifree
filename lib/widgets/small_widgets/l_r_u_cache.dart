// // Add this import
// import 'package:flutter/foundation.dart';

// // Add this class for LRU Cache
// class LRUCache {
//   final int capacity;
//   final Map<String, Uint8List> _cache = {};
//   final List<String> _keys = [];

//   LRUCache(this.capacity);

//   Uint8List? get(String key) {
//     if (!_cache.containsKey(key)) return null;
    
//     // Move to most recently used
//     _keys.remove(key);
//     _keys.add(key);
    
//     return _cache[key];
//   }

//   void put(String key, Uint8List value) {
//     if (_cache.containsKey(key)) {
//       _keys.remove(key);
//     } else if (_keys.length >= capacity) {
//       String leastUsed = _keys.removeAt(0);
//       _cache.remove(leastUsed);
//     }
    
//     _cache[key] = value;
//     _keys.add(key);
//   }
// }