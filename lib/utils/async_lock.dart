import 'dart:async';

class AsyncLock {
  final List<Future<void>> _queue = [];

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final completer = Completer<T>();

    Future<void> runAction() async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }

    _queue.add(runAction());

    if (_queue.length == 1) {
      _runQueue();
    }

    return completer.future;
  }

  Future<void> _runQueue() async {
    while (_queue.isNotEmpty) {
      final action = _queue.removeAt(0);
      await action;
    }
  }

  bool get isLocked => _queue.isNotEmpty;

  int get queueLength => _queue.length;

  void reset() {
    _queue.clear();
  }
}

class RefreshLock {
  final Map<String, AsyncLock> _locks = {};

  AsyncLock _getLock(String key) {
    return _locks.putIfAbsent(key, () => AsyncLock());
  }

  Future<T> synchronizedRefresh<T>(String key, Future<T> Function() action) {
    return _getLock(key).synchronized(action);
  }

  void reset(String key) {
    _locks[key]?.reset();
    _locks.remove(key);
  }

  void resetAll() {
    _locks.clear();
  }
}

final refreshLock = RefreshLock();
