import 'dart:async';

enum EventTopic {
  setInRepeatView,
  wsEvent,
  allowRegisterNumber,
  deleteBook,
  reimportBook,
  importBook,
  deleteVerse,
  updateBookContent,
  updateChapterContent,
  updateVerseContent,
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

typedef StreamSub<T> = List<StreamSubscription<T?>>;

extension StreamSubExt<T> on StreamSub<T> {
  void listen(
    List<EventTopic> topics,
    void Function(T? value) onData,
  ) {
    for (var topic in topics) {
      final sub = EventBus().on<T>(topic).listen(onData);
      add(sub);
    }
  }

  Future<void> cancel() async {
    for (var sub in this) {
      await sub.cancel();
    }
    clear();
  }
}
