import 'dart:async';

enum EventTopic {
  deleteBook,
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

  final _controller = StreamController<Event>.broadcast();

  void publish<T>(EventTopic topic, [T? data]) {
    _controller.add(Event<T>(topic, data));
  }

  Stream<T?> on<T>(EventTopic topic) {
    return _controller.stream.where((event) => event.topic == topic).map((event) => event.data as T?);
  }

  void dispose() {
    _controller.close();
  }
}
