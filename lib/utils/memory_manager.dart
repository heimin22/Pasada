import 'dart:collection';
import 'dart:async';
import 'package:flutter/cupertino.dart';

// this class is used to manage the memory of the app
class MemoryManager {
  MemoryManager._privateConstructor() : cacheSizeLimit = 100 {
    cache = LinkedHashMap<String, dynamic>();
  }

  static final MemoryManager instance = MemoryManager._privateConstructor();

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

  // get the current size of the cache
  int get cacheSize => cache.length;

  // throttling and debouncing
  final Map<String, Timer> throttleTimers = {};
  final Map<String, Timer> debounceTimers = {};

  // throttles a function call to a maximum of one call per duration
  // subsequent calls within the duration are ignored
  void throttle(Function func, Duration duration, String key) {
    if (!throttleTimers.containsKey(key)) {
      func();
      throttleTimers[key] = Timer(duration, () {
        throttleTimers.remove(key);
      });
    }
  }

  void debounce(Function func, Duration duration, String key) {
    debounceTimers[key]?.cancel();
    debounceTimers[key] = Timer(duration, () {
      func();
      debounceTimers.remove(key);
    });
  }

  // lifecycle methods

  // disposes of resources
  void dispose() {
    for (var timer in throttleTimers.values) {
      timer.cancel();
    }
    throttleTimers.clear();
    for (var timer in debounceTimers.values) {
      timer.cancel();
    }
    debounceTimers.clear();
    clearCache();
    debugPrint("Memory manager disposed");
  }
}
