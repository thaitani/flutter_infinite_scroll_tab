import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfiniteScrollTab Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

const contents = [
  'コンテンツAAAA',
  'コンテンツBB',
  'コンテンツCCCCCC',
  'コンテンツD',
  'コンテンツEEEEEEE',
];

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfiniteScrollTab Demo'),
      ),
      body: const _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content({Key? key}) : super(key: key);

  @override
  __ContentState createState() => __ContentState();
}

class __ContentState extends State<_Content> {
  late AutoScrollController _tabScrollController;
  late ScrollController _pageScrollController;

  int _selectIndex = 0;
  bool _isTapScrolling = false;

  int _convertContentIndex(int index) {
    return index % contents.length;
  }

  double getPageFromPixels(double pixels, double viewportDimension) {
    final double actual = pixels / viewportDimension;
    final double round = actual.roundToDouble();
    return (actual - round).abs() < precisionErrorTolerance ? round : actual;
  }

  @override
  void initState() {
    _tabScrollController = AutoScrollController(axis: Axis.horizontal)
      ..scrollToIndex(
        _selectIndex,
        preferPosition: AutoScrollPosition.middle,
      );
    _pageScrollController = ScrollController()
      ..addListener(() {
        if (_isTapScrolling) {
          return;
        }
        final page = getPageFromPixels(_pageScrollController.position.pixels,
            _pageScrollController.position.viewportDimension);
        final index = page.round();
        if (index != _selectIndex) {
          setState(() {
            _selectIndex = index;
          });
          _tabScrollController.scrollToIndex(index,
              preferPosition: AutoScrollPosition.middle);
        }
      });
    super.initState();
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  Widget tabContentBuilder(BuildContext context, int index, bool isReverse) {
    final keyIndex = isReverse ? -index - 1 : index;
    return AutoScrollTag(
      key: ValueKey(keyIndex),
      controller: _tabScrollController,
      index: keyIndex,
      child: InkWell(
        onTap: () async {
          setState(() {
            _isTapScrolling = true;
            _selectIndex = keyIndex;
          });
          _tabScrollController.scrollToIndex(keyIndex,
              preferPosition: AutoScrollPosition.middle);
          await _pageScrollController.animateTo(
              _pageScrollController.position.viewportDimension * keyIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
          setState(() {
            _isTapScrolling = false;
          });
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: keyIndex == _selectIndex
                    ? Colors.black
                    : Colors.transparent,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
            child: Tab(
              text: '${contents[_convertContentIndex(keyIndex)]} #$keyIndex',
            ),
          ),
        ),
      ),
    );
  }

  Widget contentBuilder(BuildContext context, int index, bool isReverse) {
    final keyIndex = isReverse ? -index - 1 : index;
    return Container(
      alignment: Alignment.center,
      color: Colors.grey[_convertContentIndex(keyIndex) * 100],
      child: Text(
        '${contents[_convertContentIndex(keyIndex)]} #$keyIndex',
        style: const TextStyle(fontSize: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final axisDirection = getAxisDirectionFromAxisReverseAndDirectionality(
      context,
      Axis.horizontal,
      false,
    );
    Key forwardTabKey = UniqueKey();
    Widget forwardTabList = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => tabContentBuilder(context, index, false),
      ),
      key: forwardTabKey,
    );

    Widget reverseTabList = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => tabContentBuilder(context, index, true),
      ),
    );

    Key forwardContentKey = UniqueKey();
    Widget forwardContent = SliverFillViewport(
      delegate: SliverChildBuilderDelegate(
        (context, index) => contentBuilder(context, index, false),
      ),
      key: forwardContentKey,
    );

    Widget reverseContent = SliverFillViewport(
      delegate: SliverChildBuilderDelegate(
        (context, index) => contentBuilder(context, index, true),
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: 50,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
            ),
            child: Scrollable(
              controller: _tabScrollController,
              axisDirection: axisDirection,
              viewportBuilder: (BuildContext context, ViewportOffset offset) {
                return Viewport(
                  offset: offset,
                  center: forwardTabKey,
                  slivers: [
                    reverseTabList,
                    forwardTabList,
                  ],
                  axisDirection: axisDirection,
                );
              },
            ),
          ),
        ),
        Expanded(
          child: Scrollable(
            physics: const PageScrollPhysics(),
            controller: _pageScrollController,
            axisDirection: axisDirection,
            viewportBuilder: (BuildContext context, ViewportOffset offset) {
              return Viewport(
                offset: offset,
                center: forwardContentKey,
                slivers: [
                  reverseContent,
                  forwardContent,
                ],
                axisDirection: axisDirection,
              );
            },
          ),
        ),
      ],
    );
  }
}
