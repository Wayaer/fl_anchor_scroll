import 'package:example/src/anchor_scroll.dart';
import 'package:example/src/fl_anchor_scroll.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                push(const FlAnchorScrollPage());
              },
              child: const Text('FlAnchorScrollTag')),
          20.heightBox,
          ElevatedButton(
              onPressed: () {
                push(const FlAnchorScrollSliverGridPage());
              },
              child: const Text('FlAnchorScrollController with SliverGrid')),
          20.heightBox,
          ElevatedButton(
              onPressed: () {
                push(const FlAnchorScrollSliverListPage());
              },
              child: const Text('FlAnchorScrollController with SliverList')),
          20.heightBox,
          ElevatedButton(
              onPressed: () {
                push(const AnchorScrollBuilderPage());
              },
              child: const Text('AnchorScrollController')),
        ]);
  }
}

class ElevatedText extends StatelessWidget {
  const ElevatedText(this.text, {super.key, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onTap, child: Text(text));
}

class AppBarText extends AppBar {
  AppBarText(String text, {super.key})
      : super(
            elevation: 0,
            title: BText(text, fontSize: 18, fontWeight: FontWeight.bold),
            centerTitle: true);
}

/// ExtendedScaffold
class ExtendedScaffold extends StatelessWidget {
  const ExtendedScaffold(
      {super.key,
      this.safeLeft = false,
      this.safeTop = false,
      this.safeRight = false,
      this.safeBottom = false,
      this.isStack = false,
      this.isScroll = false,
      this.isCloseOverlay = true,
      this.appBar,
      this.child,
      this.padding,
      this.floatingActionButton,
      this.bottomNavigationBar,

      /// 类似于 Android 中的 android:windowSoftInputMode=”adjustResize”，
      /// 控制界面内容 body 是否重新布局来避免底部被覆盖了，比如当键盘显示的时候，
      /// 重新布局避免被键盘盖住内容。默认值为 true。
      this.resizeToAvoidBottomInset,
      this.children,
      this.mainAxisAlignment = MainAxisAlignment.start,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.refreshConfig,
      this.enableDoubleClickExit = false});

  /// 相当于给[body] 套用 [Column]、[Row]、[Stack]
  final List<Widget>? children;

  /// [children].length > 0 && [isStack]=false 有效;
  final MainAxisAlignment mainAxisAlignment;

  /// [children].length > 0 && [isStack]=false 有效;
  final CrossAxisAlignment crossAxisAlignment;

  /// [children].length > 0有效;
  /// 添加 [Stack]组件
  final bool isStack;

  /// 是否添加滚动组件
  final bool isScroll;

  final EdgeInsetsGeometry? padding;

  /// true 点击android实体返回按键先关闭Overlay【toast loading ...】但不pop 当前页面
  /// false 点击android实体返回按键先关闭Overlay【toast loading ...】并pop 当前页面
  final bool isCloseOverlay;

  /// ****** 刷新组件相关 ******  ///
  final RefreshConfig? refreshConfig;

  /// Scaffold相关属性
  final Widget? child;

  final Widget? appBar;
  final Widget? floatingActionButton;

  final Widget? bottomNavigationBar;

  final bool? resizeToAvoidBottomInset;

  /// ****** [SafeArea] ****** ///
  final bool safeLeft;
  final bool safeTop;
  final bool safeRight;
  final bool safeBottom;
  final bool enableDoubleClickExit;

  static DateTime? _dateTime;

  @override
  Widget build(BuildContext context) {
    final Widget scaffold = Scaffold(
        key: key,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        appBar: buildAppBar(context),
        bottomNavigationBar: bottomNavigationBar,
        body: universal);
    return isCloseOverlay
        ? ExtendedPopScope(
            isCloseOverlay: isCloseOverlay,
            onPopInvoked: (bool didPop, bool didCloseOverlay) {
              if (didCloseOverlay || didPop) return;
              if (enableDoubleClickExit) {
                final now = DateTime.now();
                if (_dateTime != null &&
                    now.difference(_dateTime!).inMilliseconds < 2500) {
                  SystemNavigator.pop();
                } else {
                  _dateTime = now;
                  showToast('再次点击返回键退出',
                      options: const ToastOptions(
                          duration: Duration(milliseconds: 1500)));
                }
              } else {
                pop();
              }
            },
            child: scaffold)
        : scaffold;
  }

  PreferredSizeWidget? buildAppBar(BuildContext context) {
    if (appBar is AppBar) return appBar as AppBar;
    return appBar == null
        ? null
        : PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight - 12),
            child: appBar!);
  }

  Universal get universal => Universal(
      expand: true,
      refreshConfig: refreshConfig,
      padding: padding,
      isScroll: isScroll,
      safeLeft: safeLeft,
      safeTop: safeTop,
      safeRight: safeRight,
      safeBottom: safeBottom,
      isStack: isStack,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      child: child,
      children: children);
}
