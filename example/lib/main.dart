import 'package:example/src/anchor_scroll.dart';
import 'package:example/src/sliver_grid.dart';
import 'package:example/src/sliver_list.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'FlAnchorScroll',
      navigatorKey: FlExtended().navigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(title: const Text('FlAnchorScroll')),
          body: const _App())));
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return Universal(
        width: double.infinity,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
              onPressed: () {
                push(const AnchorScrollPage());
              },
              child: const Text('AnchorScrollTag')),
          ElevatedButton(
              onPressed: () {
                push(const AnchorScrollSliverGridPage());
              },
              child: const Text('AnchorScrollController with SliverGrid')),
          ElevatedButton(
              onPressed: () {
                push(const AnchorScrollSliverListPage());
              },
              child: const Text('AnchorScrollController with SliverList')),
        ]);
  }
}
