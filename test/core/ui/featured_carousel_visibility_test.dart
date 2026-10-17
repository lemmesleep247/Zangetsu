import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watch_app/core/models/media_item.dart';
import 'package:watch_app/core/models/provider_info.dart';
import 'package:watch_app/core/ui/featured_carousel.dart';
import 'package:watch_app/core/ui/route_observer.dart';

MediaItem _item(String id) => MediaItem(
  id: id,
  title: 'Show $id',
  url: 'https://example.test/$id',
  type: ProviderType.anime,
  sourceId: 'test',
);

void main() {
  testWidgets('pauses off-tab and resumes when Home is selected', (
    tester,
  ) async {
    final builtHeroIds = <String>{};
    final isHomeActive = ValueNotifier(true);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: isHomeActive,
          builder: (context, active, _) => Scaffold(
            body: FeaturedCarousel(
              items: [_item('first'), _item('second')],
              inList: (_) => false,
              onPlay: (_) {},
              onInfo: (_) {},
              onToggleList: (_) {},
              style: HeroTransition.cinematic,
              isActive: active,
              meta: (item) {
                builtHeroIds.add(item.id);
                return Future.value(null);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    builtHeroIds.clear();

    await tester.pump(const Duration(seconds: 2));
    isHomeActive.value = false;
    await tester.pump();
    builtHeroIds.clear();
    await tester.pump(const Duration(seconds: 5));
    expect(builtHeroIds, isNot(contains('second')));

    isHomeActive.value = true;
    await tester.pump();
    builtHeroIds.clear();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(builtHeroIds, contains('second'));

    isHomeActive.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pauses while a detail route covers it and resumes on return', (
    tester,
  ) async {
    final builtHeroIds = <String>{};
    late BuildContext homeContext;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [appRouteObserver],
        home: Builder(
          builder: (context) {
            homeContext = context;
            return Scaffold(
              body: FeaturedCarousel(
                items: [_item('first'), _item('second')],
                inList: (_) => false,
                onPlay: (_) {},
                onInfo: (_) {},
                onToggleList: (_) {},
                style: HeroTransition.cinematic,
                meta: (item) {
                  builtHeroIds.add(item.id);
                  return Future.value(null);
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    builtHeroIds.clear();

    await tester.pump(const Duration(seconds: 2));
    final detailRoute = Navigator.of(homeContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detail')),
      ),
    );
    await tester.pumpAndSettle();
    builtHeroIds.clear();

    await tester.pump(const Duration(seconds: 5));
    expect(
      builtHeroIds,
      isNot(contains('second')),
      reason: 'the hidden carousel should not advance or build another hero',
    );

    Navigator.of(homeContext).pop();
    await detailRoute;
    await tester.pumpAndSettle();
    builtHeroIds.clear();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(builtHeroIds, contains('second'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
