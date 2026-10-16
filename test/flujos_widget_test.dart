import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';
import 'support/widget_helpers.dart';

void main() {
  testWidgets('detalle API, favorito, filtro y alta desde plantilla', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    expectTouchTarget(tester, find.byKey(const Key('favorite-1')));
    expectTouchTarget(tester, find.byType(FilterChip));
    await tapVisible(tester, find.byKey(const Key('favorite-1')));
    await tapVisible(tester, find.text('Solo favoritos'));
    expect(find.text('Idea 1'), findsOneWidget);
    expect(find.text('Idea 2'), findsNothing);
    await tapVisible(tester, find.text('Idea 1'));
    expect(find.text('Diez minutos para aprender.'), findsOneWidget);
    await tapVisible(tester, find.text('Crear desde plantilla'));
    expect(find.text('Nuevo hábito'), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('habit-title')),
    );
    expect(field.controller?.text, 'Idea 1');
    expectTouchTarget(tester, find.byKey(const Key('habit-save')));
    await tapVisible(tester, find.byKey(const Key('habit-save')));
    await tapVisible(tester, find.text('Mis hábitos'));
    expect(find.text('Idea 1'), findsOneWidget);
    expect(f.backend.habits[1]!.values.single['plantilla_id'], 1);
  });

  testWidgets(
    'CRUD manual valida, edita, completa, reabre y confirma eliminación',
    (tester) async {
      final f = Fixture();
      await mountFixture(tester, f, login: true);
      await tapVisible(tester, find.text('Mis hábitos'));
      expect(find.text('Un pequeño paso cuenta'), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('habit-create')));
      await tapVisible(tester, find.byKey(const Key('habit-save')));
      expect(find.text('Escriba un título.'), findsOneWidget);
      expect(f.adapter.matching('POST', '/habitos'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('habit-title')),
        'Organizar escritorio',
      );
      await tapVisible(tester, find.byKey(const Key('habit-save')));
      expect(find.text('Organizar escritorio'), findsOneWidget);
      final id = f.binding.habitos.items.single.id;
      await tapVisible(tester, find.byKey(Key('edit-$id')));
      await tester.enterText(
        find.byKey(const Key('habit-title')),
        'Organizar libros',
      );
      await tapVisible(tester, find.byKey(const Key('habit-save')));
      expect(find.text('Organizar libros'), findsOneWidget);
      expectTouchTarget(tester, find.byKey(Key('complete-$id')));
      await tapVisible(tester, find.byKey(Key('complete-$id')));
      expect(find.text('1 de 1 completados'), findsOneWidget);
      expect(f.backend.habits[1]![id]!['completado'], true);
      await tapVisible(tester, find.byKey(Key('complete-$id')));
      expect(find.text('0 de 1 completados'), findsOneWidget);
      await tapVisible(tester, find.byKey(Key('delete-$id')));
      await tapVisible(tester, find.text('Conservar'));
      expect(f.adapter.matching('DELETE', '/habitos/$id'), isEmpty);
      expect(f.backend.habits[1], hasLength(1));
      await tapVisible(tester, find.byKey(Key('delete-$id')));
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Eliminar'));
      expect(f.adapter.matching('DELETE', '/habitos/$id'), hasLength(1));
      expect(f.backend.habits[1], isEmpty);
      expect(find.text('Un pequeño paso cuenta'), findsOneWidget);
    },
  );

  testWidgets(
    'asistente muestra propuesta; cancelar cero y confirmar una creación',
    (tester) async {
      final f = Fixture();
      await mountFixture(tester, f, login: true);
      await tapVisible(tester, find.text('Asistente'));
      expect(find.text('0 completados · 0 en su rutina'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('assistant-input')),
        'Proponga una lectura',
      );
      await tapVisible(tester, find.byKey(const Key('assistant-consult')));
      expect(find.text('Lectura breve'), findsOneWidget);
      expectTouchTarget(tester, find.byKey(const Key('assistant-confirm')));
      expectTouchTarget(tester, find.byKey(const Key('assistant-cancel')));
      await tapVisible(tester, find.byKey(const Key('assistant-cancel')));
      expect(f.adapter.matching('POST', '/habitos'), isEmpty);
      await tester.enterText(
        find.byKey(const Key('assistant-input')),
        'Proponga una lectura',
      );
      await tapVisible(tester, find.byKey(const Key('assistant-consult')));
      await tapVisible(tester, find.byKey(const Key('assistant-confirm')));
      expect(f.adapter.matching('POST', '/habitos'), hasLength(1));
      expect(find.text('Propuesta guardada en Mis hábitos.'), findsOneWidget);
      expect(find.text('0 completados · 1 en su rutina'), findsOneWidget);
      await tapVisible(tester, find.text('Mis hábitos'));
      expect(find.text('Lectura breve'), findsOneWidget);
    },
  );

  testWidgets('salir de Asistente descarta propuesta y formulario', (
    tester,
  ) async {
    final f = Fixture();
    await mountFixture(tester, f, login: true);
    await tapVisible(tester, find.text('Asistente'));
    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Proponga algo',
    );
    await tapVisible(tester, find.byKey(const Key('assistant-consult')));
    await tapVisible(tester, find.text('Catálogo'));
    await tapVisible(tester, find.text('Asistente'));
    expect(find.byKey(const Key('assistant-confirm')), findsNothing);
    expect(f.binding.asistente.input.text, isEmpty);
    expect(f.adapter.matching('POST', '/habitos'), isEmpty);
  });
}
