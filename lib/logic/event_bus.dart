import 'dart:async';

enum EventTopic {
  setInRepeatView,
  wsEvent,
  allowRegisterNumber,
  createBook,
  importBook,
  reimportBook,
  deleteBook,
  updateBookContent,
  deleteChapter,
  addChapter,
  updateChapterContent,
  deleteVerse,
  addVerse,
  updateVerseContent,
  updateVerseProgress,
}

class Event<T> {
  final EventTopic topic;
  final T? data;

  Event(this.topic, [this.data]);
}

class EventBus {
  EventBus._internal();

  static final EventBus _instance = EventBus._internal();

  factory EventBus() => _instance;

  // topic -> { id -> callback }
  final Map<EventTopic, Map<int, Function(dynamic)>> _listeners = {};

  int _nextId = 0;

  /// Subscribe and return a unique ID for this listener
  int on<T>(EventTopic topic, void Function(T? data) callback) {
    final id = ++_nextId;
    _listeners.putIfAbsent(topic, () => {});
    _listeners[topic]![id] = (dynamic data) => callback(data as T?);
    return id;
  }

  /// Publish an event to all listeners
  void publish<T>(EventTopic topic, [T? data]) {
    final listeners = _listeners[topic];
    if (listeners == null) return;
    for (final id in (listeners.keys.toList()..sort())) {
      listeners[id]?.call(data);
    }
  }

  /// Remove listener by ID or all by topic
  void off(EventTopic topic, [int? id]) {
    if (!_listeners.containsKey(topic)) return;

    if (id == null) {
      _listeners.remove(topic); // remove all under topic
    } else {
      _listeners[topic]!.remove(id);
      if (_listeners[topic]!.isEmpty) {
        _listeners.remove(topic);
      }
    }
  }

  /// Clear all topics and listeners
  void clear() {
    _listeners.clear();
  }
}

class Sub<T> {
  final EventTopic topic;
  final int id;
  T? data;

  Sub({
    required this.topic,
    required this.id,
  });
}

typedef SubList<T> = List<Sub<T>>;

extension StreamSubExt<T> on SubList<T> {
  void on(
    List<EventTopic> topics,
    void Function(T? value) onData,
  ) {
    for (var topic in topics) {
      final id = EventBus().on<T>(topic, onData);
      add(Sub(topic: topic, id: id));
    }
  }

  Future<void> off() async {
    for (var sub in this) {
      EventBus().off(sub.topic, sub.id);
    }
    clear();
  }
}
