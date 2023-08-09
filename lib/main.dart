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

const _contents = [
  'コンテンツAAAA',
  'コンテンツBB',
  'コンテンツCCCCCC',
  'コンテンツD',
  'コンテンツEEEEEEE',
  'コンテンツFFFFF',
  'コンテンツG',
  'コンテンツH',
  'コンテンツII',
  'コンテンツJJJJ',
  'コンテンツKKK',
  'コンテンツLLLLL',
  'コンテンツMMMMM',
  'コンテンツNNNN',
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfiniteScrollTab Demo'),
      ),
      body: _Content(
        width: MediaQuery.of(context).size.width,
        initialIndex: 13,
      ),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content({
    this.initialIndex = 0,
    required this.width,
  });

  final int initialIndex;
  final double width;

  @override
  __ContentState createState() => __ContentState();
}

class __ContentState extends State<_Content> {
  late AutoScrollController _tabScrollController;
  late ScrollController _pageScrollController;

  int _selectIndex = 0;
  bool _isTapScrolling = false;

  String _convertContent(int index) {
    return _contents[index % _contents.length];
  }

  double _getPageFromPixels(ScrollPosition position) {
    final actual = position.pixels / position.viewportDimension;
    final round = actual.roundToDouble();
    return (actual - round).abs() < precisionErrorTolerance ? round : actual;
  }

  @override
  void initState() {
    _selectIndex = widget.initialIndex;
    _tabScrollController = AutoScrollController(
      axis: Axis.horizontal,
    )..scrollToIndex(
        _selectIndex,
        preferPosition: AutoScrollPosition.middle,
      );
    _pageScrollController =
        ScrollController(initialScrollOffset: widget.width * _selectIndex)
          ..addListener(() {
            if (_isTapScrolling) {
              return;
            }
            final page = _getPageFromPixels(
              _pageScrollController.position,
            );
            final index = page.round();
            if (index == _selectIndex) {
              return;
            }
            setState(() {
              _selectIndex = index;
            });
            _tabScrollController.scrollToIndex(
              index,
              preferPosition: AutoScrollPosition.middle,
            );
          });
    super.initState();
  }

  @override
  void dispose() {
    _tabScrollController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  Widget _tabContentBuilder({
    required BuildContext context,
    required int index,
  }) {
    return AutoScrollTag(
      key: ValueKey(index),
      controller: _tabScrollController,
      index: index,
      child: InkWell(
        onTap: () async {
          setState(() {
            _isTapScrolling = true;
            _selectIndex = index;
          });
          await Future.wait([
            _tabScrollController.scrollToIndex(
              index,
              preferPosition: AutoScrollPosition.middle,
            ),
            _pageScrollController.animateTo(
              _pageScrollController.position.viewportDimension * index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
          ]);
          setState(() {
            _isTapScrolling = false;
          });
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border(
              bottom: BorderSide(
                color:
                    index == _selectIndex ? Colors.white : Colors.transparent,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Tab(
              child: Text(
                '${_convertContent(index)} #$index',
                style: TextStyle(
                  color: index == _selectIndex ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contentBuilder({
    required BuildContext context,
    required int index,
  }) {
    final contentIndex = index % _contents.length;
    return Container(
      alignment: Alignment.center,
      color: Colors.grey[contentIndex * 100],
      child: Text(
        '${_convertContent(index)} #$index',
        style: const TextStyle(fontSize: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey,
                  width: 0.5,
                ),
              ),
            ),
            child: InfiniteListView(
              itemBuilder: (context, index) => _tabContentBuilder(
                context: context,
                index: index,
              ),
              controller: _tabScrollController,
              axis: Axis.horizontal,
            ),
          ),
        ),
        Expanded(
          child: InfiniteListView(
            itemBuilder: (context, index) => _contentBuilder(
              context: context,
              index: index,
            ),
            physics: const PageScrollPhysics(),
            controller: _pageScrollController,
            axis: Axis.horizontal,
            expand: true,
          ),
        ),
      ],
    );
  }
}

class InfiniteListView extends StatelessWidget {
  const InfiniteListView({
    super.key,
    required this.itemBuilder,
    this.controller,
    this.axis = Axis.vertical,
    this.physics,
    this.expand = false,
  });

  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Axis axis;
  final bool expand;

  SliverChildDelegate _itemBuilderDelegate({
    required bool isReverse,
  }) {
    return SliverChildBuilderDelegate((context, index) {
      final i = isReverse ? -index - 1 : index;
      return itemBuilder(
        context,
        i,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final axisDirection = getAxisDirectionFromAxisReverseAndDirectionality(
      context,
      axis,
      false,
    );

    final forwardContentKey = UniqueKey();
    final forwardContent = expand
        ? SliverFillViewport(
            key: forwardContentKey,
            delegate: _itemBuilderDelegate(isReverse: false),
          )
        : SliverList(
            key: forwardContentKey,
            delegate: _itemBuilderDelegate(isReverse: false),
          );

    final reverseContent = expand
        ? SliverFillViewport(
            delegate: _itemBuilderDelegate(isReverse: true),
          )
        : SliverList(
            delegate: _itemBuilderDelegate(isReverse: true),
          );
    return Scrollable(
      physics: physics,
      controller: controller,
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
    );
  }
}
