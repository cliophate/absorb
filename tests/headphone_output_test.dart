import 'package:absorb/widgets/headphone_output_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('com.absorb.headphones');
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> state;
  late List<String> selections;
  bool rejectSelection = false;
  bool rejectState = false;

  setUp(() {
    selections = [];
    rejectSelection = false;
    rejectState = false;
    state = {
      'selectedKey': '',
      'selectedName': '',
      'connected': false,
      'devices': [
        {'key': '8:buds', 'name': 'Pixel Buds', 'bluetooth': true},
      ],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'state' && rejectState) {
            throw PlatformException(
              code: 'routing_error',
              message: 'Could not read audio outputs.',
            );
          }
          if (call.method == 'select') {
            if (rejectSelection) {
              throw PlatformException(
                code: 'disconnected',
                message: 'Headphones disconnected.',
              );
            }
            final key = (call.arguments as Map)['key'] as String;
            selections.add(key);
            state = {
              ...state,
              'selectedKey': key,
              'selectedName': 'Pixel Buds',
              'connected': key.isNotEmpty,
            };
          }
          return state;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HeadphoneOutputSheet())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selects headphones and can restore normal output', (
    tester,
  ) async {
    await openSheet(tester);
    await tester.tap(find.text('Pixel Buds'));
    await tester.pumpAndSettle();
    expect(selections, ['8:buds']);
    expect(find.text('Selected for headphone mode'), findsOneWidget);

    await tester.tap(find.text('Normal audio output'));
    await tester.pumpAndSettle();
    expect(selections, ['8:buds', '']);
    expect(find.text('Selected for headphone mode'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'reports a disconnected selection and keeps the normal-output escape',
    (tester) async {
      state = {
        ...state,
        'selectedKey': '8:buds',
        'selectedName': 'Pixel Buds',
        'connected': false,
        'devices': [],
      };
      await openSheet(tester);
      expect(
        find.text('Pixel Buds disconnected. Playback will stay paused.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Normal audio output'));
      await tester.pumpAndSettle();
      expect(selections, ['']);
      expect(find.textContaining('Playback will stay paused.'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('does not claim a device was selected after a routing error', (
    tester,
  ) async {
    rejectSelection = true;
    await openSheet(tester);
    await tester.tap(find.text('Pixel Buds'));
    await tester.pumpAndSettle();
    expect(find.text('Headphones disconnected.'), findsOneWidget);
    expect(find.text('Selected for headphone mode'), findsNothing);
    expect(selections, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('clears a read error after a successful refresh', (tester) async {
    rejectState = true;
    await openSheet(tester);
    expect(find.text('Could not read audio outputs.'), findsOneWidget);

    rejectState = false;
    await tester.tap(find.text('Refresh devices'));
    await tester.pumpAndSettle();
    try {
      expect(find.text('Could not read audio outputs.'), findsNothing);
      expect(find.text('Pixel Buds'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
