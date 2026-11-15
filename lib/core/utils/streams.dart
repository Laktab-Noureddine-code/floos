import 'dart:async';

/// Combines the latest values of two streams.
Stream<R> combineLatest2<A, B, R>(Stream<A> a, Stream<B> b, R Function(A, B) combine) {
  late StreamController<R> controller;
  StreamSubscription<A>? sa;
  StreamSubscription<B>? sb;
  A? va;
  B? vb;
  var hasA = false;
  var hasB = false;
  void emit() {
    if (hasA && hasB) controller.add(combine(va as A, vb as B));
  }

  controller = StreamController<R>(
    onListen: () {
      sa = a.listen((v) {
        va = v;
        hasA = true;
        emit();
      }, onError: controller.addError);
      sb = b.listen((v) {
        vb = v;
        hasB = true;
        emit();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await sa?.cancel();
      await sb?.cancel();
    },
  );
  return controller.stream;
}

/// Combines the latest values of three streams.
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combine,
) => combineLatest2<(A, B), C, R>(
  combineLatest2<A, B, (A, B)>(a, b, (x, y) => (x, y)),
  c,
  (ab, z) => combine(ab.$1, ab.$2, z),
);
