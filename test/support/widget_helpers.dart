import 'dart:async';

import 'package:bto_habitos/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

Future<void> mountFixture(
  WidgetTester tester,
  Fixture fixture, {
  bool login = false,
}) async {
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpOperation(tester, fixture.close());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  if (login) {
    await pumpOperation(tester, fixture.login());
    await pumpOperation(tester, fixture.ready());
  }
  await tester.pumpWidget(BtoHabitosApp(binding: fixture.binding));
  await settleOperations(tester);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty &&
      find.byType(Scrollable).evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(
      finder,
      -160,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 15,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump(Duration.zero);
  await tester.ensureVisible(finder);
  await tester.pump(Duration.zero);
  await tester.tap(finder.hitTestable());
  await settleOperations(tester);
}

Future<void> settleOperations(WidgetTester tester) async {
  final apps = find.byType(BtoHabitosApp).evaluate();
  bool busy() {
    if (apps.isEmpty) return false;
    final b = (apps.single.widget as BtoHabitosApp).binding;
    return b.auth.busy.value ||
        b.auth.restoring.value ||
        b.catalogo.loading.value ||
        b.catalogo.favoritesLoading.value ||
        b.habitos.loading.value ||
        b.habitos.mutating.value ||
        b.asistente.loading.value ||
        b.asistente.confirming.value;
  }

  // Dio usa tareas de evento de duración cero: avanzar frames hasta el estado
  // observable, sin esperar tiempo real ni adivinar una duración de red.
  await tester.pump(Duration.zero);
  for (var frame = 0; busy() && frame < 100; frame++) {
    await tester.pump(Duration.zero);
  }
  expect(
    busy(),
    isFalse,
    reason: 'Las operaciones deben liberar sus controles',
  );
  await tester.pumpAndSettle();
}

Future<void> pumpOperation(WidgetTester tester, Future<void> operation) async {
  final done = Completer<void>();
  Object? failure;
  operation.then(
    (_) => done.complete(),
    onError: (Object e) {
      failure = e;
      done.complete();
    },
  );
  await pumpToBarrier(tester, done);
  if (failure != null) throw failure!;
}

Future<void> pumpToBarrier(WidgetTester tester, Completer<void> barrier) async {
  for (var frame = 0; !barrier.isCompleted && frame < 100; frame++) {
    await tester.pump(Duration.zero);
  }
  expect(
    barrier.isCompleted,
    isTrue,
    reason: 'La operación debe llegar a la barrera',
  );
  await barrier.future;
  await tester.pump(Duration.zero);
}

void expectTouchTarget(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}
