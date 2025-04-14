import 'dart:collection';
import 'dart:async';

import 'package:flutter/cupertino.dart';

// this class is used to manage the memory of the app
class MemoryManager {
  MemoryManager.priavteConstructor();

  static final MemoryManager instance = MemoryManager.priavteConstructor();

  factory MemoryManager() {
    return instance;
  }

  // maximum number of items in the cache
  final int cacheSizeLimit;

  // internal cache storage using linked hash map para sa LRU behavior
  late final LinkedHashMap<String, dynamic> cache;

  MemoryManager.privateConstructor({this.cacheSizeLimit = 100}) {
    cache = LinkedHashMap<String, dynamic>();
  }

  // add an item to the cache
  // if yung cache nag-exceed duon sa cacheSizeLimit, remove the oldest item
  void addToCache(String key, dynamic value) {
    // if they key exists, remove muna duon sa update ng position
    if (cache.containsKey(key)) {
      cache.remove(key);
    }

    // add natin yung new value, making it the most recently used
    cache[key] = value;
    if (cache.length > cacheSizeLimit) {
      cache.remove(cache.keys.first);
    }
    debugPrint('Cache size: ${cache.length}');
  }

  // retrieves an item from the cache
  dynamic getFromCache(String key) {
    final value = cache.remove(key);
    if (value != null) {
      cache[key] = value;
    }
    return value;
  }

  // clears the entire cache
  void clearCache() {
    cache.clear();
    debugPrint("Cache cleared");
  }

  // clear yung specific item duon sa cache
  void clearCacheItem(String key) {
    cache.remove(key);
    debugPrint("Item $key cleared");
  }
}
