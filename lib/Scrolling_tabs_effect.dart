import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'app_color.dart';
import 'constants.dart';
import 'data_source.dart';
import 'models/restaurant_detail_model.dart';
import 'models/restaurant_detail_with_food_group.dart';


class ScrollingTabsEffect extends StatefulWidget {
  @override
  _ScrollingTabsEffectState createState() =>
      _ScrollingTabsEffectState();
}

class _ScrollingTabsEffectState
    extends State<ScrollingTabsEffect>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  /// Controller to scroll or jump to a particular item.
  final ItemScrollController itemScrollController = ItemScrollController();

  /// Listener that reports the position of items when the list is scrolled.
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  AutoScrollController _autoScrollController;
  final scrollDirection = Axis.vertical;
  RestaurantDetailModel restaurantDetail;
  RestaurantDetailFoodWithGroupModel foodItems;

  // bool isExpanded = true;

  TabController _tabController;

  //here we want to add or remove items to the map based on the visibility of the items
  //so that we can calculate the current index of tab bar on the visibility of the current item
  final Map<int, bool> _visibleItems = {0: true};

  bool _isAppBarExpanded(BuildContext context) {
    if (!_autoScrollController.hasClients) return false;
    print(
        "The offset scrolled now is ${_autoScrollController.offset} and the height is now ${(MediaQuery.of(context).size.height / 1.6 - kToolbarHeight)}");

    return _autoScrollController.offset >
        (MediaQuery.of(context).size.height / 1.6 - kToolbarHeight);
  }

  @override
  void initState() {
    restaurantDetail =
        RestaurantDetailModel.fromJson(restaurantDetailData["data"]);
    foodItems =
        RestaurantDetailFoodWithGroupModel.fromJson(restaurantDetailWithFood);

    _tabController = TabController(

      length: foodItems?.data?.length,
      vsync: this,
    );
    _autoScrollController = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
      axis: scrollDirection,
    );

    super.initState();
  }

  Future _scrollToIndex(int index) async {
    print(
        "The offset scrolled now is before updating ${_autoScrollController.offset} and the height is now ${(MediaQuery.of(context).size.height / 1.6 - kToolbarHeight)}");

    print("The index to scroll to item is this $index");
    await _autoScrollController.scrollToIndex(index,
        preferPosition: AutoScrollPosition.begin);
    await _autoScrollController.highlight(index,
        animated: true, highlightDuration: Duration(seconds: 2));
    // itemScrollController.jumpTo(index: index, alignment: 1.00);
  }

  Widget _wrapScrollTag({int index, Widget child}) {
    return AutoScrollTag(
      key: ValueKey(index),
      controller: _autoScrollController,
      index: index,
      child: child,
      highlightColor: Colors.black.withOpacity(0.1),
    );
  }



  Widget _buildSliverAppbar(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SliverAppBar(
      brightness: Brightness.light,
      backgroundColor: Colors.white,
      pinned: true,
      snap: false,
      // expandedHeight: size.height / 1.33,
      leading:
           IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: blackColor,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
      actions: [
        IconButton(
                icon: Icon(
                  Icons.search,
                  size: 32,
                  color: blackColor,
                ),
                onPressed: () {
                  _showSearchSection(context);
                },
              ),
      ],
      title: Text(
              restaurantDetail?.name ?? "",
              style: TextStyle(color: blackColor),
            ),
      bottom: TabBar(
        controller: _tabController,
        labelStyle:
            TextStyle(color: blackColor, fontWeight: FontWeight.bold),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        indicator: BoxDecoration(
          color: Colors.red[300],
          borderRadius: BorderRadius.circular(24),
        ),
        indicatorColor: blackColor,
        indicatorWeight: 2.5,

        isScrollable: true,
        indicatorPadding: EdgeInsets.symmetric(horizontal: 4),
        onTap: (index) async {
          _scrollToIndex(index);
        },
        tabs: foodItems?.data?.map((e) {
          return Tab(
            child: Text("${e.name}"),

            // text: 'Detail Business',
            // icon: Icon(Icons.three_k,color: whiteColor,),
          );
        })?.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: CustomScrollView(
        controller: _autoScrollController,
        // shrinkWrap: true,
        slivers: <Widget>[
          _buildSliverAppbar(context),
          SliverList(
              delegate: SliverChildListDelegate(
            [
              _buildFoodCategoryBody(),
            ],
          )),
        ],
      ),
    );
  }

  ListView _buildFoodCategoryBody() {
    return ListView.builder(
      // itemScrollController: itemScrollController,
      // itemPositionsListener: itemPositionsListener,
      shrinkWrap: true,
      addAutomaticKeepAlives: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: foodItems?.data?.length,
      itemBuilder: (context, index) => VisibilityDetector(
        key: Key(foodItems?.data[index].sId),
        onVisibilityChanged: (info) {
          // if (!_autoScrollController.isAutoScrolling) return;
          var visiblePercentage = info.visibleFraction * 100;
          if (visiblePercentage > 90) {
            _visibleItems.putIfAbsent(index, () => true);
          } else {
            _visibleItems.remove(index);
          }

          _calculateIndexAndJumpToTab(_visibleItems);
        },
        child: _wrapScrollTag(
          index: index,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildFoodItemCategoryTitle(context, foodItems?.data[index].name),
              SizedBox(
                height: 16,
              ),
              ..._buildCategoryItems(context, index),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategoryItems(BuildContext context, int index) {
    if (foodItems.data[index].foods.isEmpty) return [Container()];
    List<Widget> _list = [];
    for (int i = 0; i < foodItems.data[index].foods.length; i++) {
      _list.add(_buildSingleFoodItemByCategory(
          context, foodItems.data[index].foods[i]));
    }
    return _list;
  }

  InkWell _buildSingleFoodItemByCategory(BuildContext context, Foods food) {
    return InkWell(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(
                            food.name,
                            style: Theme.of(context).textTheme.subtitle2,
                            textAlign: TextAlign.start,
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            food.subTitle,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        Container(
                          child: Text(
                            "\$${food.price}",
                            style: Theme.of(context).textTheme.subtitle2,
                            textAlign: TextAlign.start,
                          ),
                          alignment: Alignment.centerLeft,
                        ),
                      ],
                    )),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  flex: 1,
                  child: FadeInImage.assetNetwork(
                    placeholder: "assets/images/pizza_image.jpg",
                    image: food.images == null || food.images.isEmpty
                        ? NO_IMAGE_FOUND_URL
                        : getImageUrlFromApi(food.images.first),
                    width: MediaQuery.of(context).size.width,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1,
            color: redColor,
          )
        ],
      ),
      onTap: () {
        // todo do something
      },
    );
  }

  Container buildFoodItemCategoryTitle(BuildContext context, String name) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.all(8),
      child: Text(name ?? "Picked for you",
          style: Theme.of(context)
              .textTheme
              .headline6
              .copyWith(fontWeight: FontWeight.bold)),
    );
  }


  void _calculateIndexAndJumpToTab(Map<int, bool> visibleItems) async {
    List<int> indexes = List.from(_visibleItems.keys.toList());
    indexes.sort();
    int topMostVisibleItem = indexes.first;
    _tabController.animateTo(topMostVisibleItem);
  }

  @override
  bool get wantKeepAlive => true;

  void _showSearchSection(BuildContext context) async {
    // var result = await showSearch(
    //     context: context,
    //     delegate: AppBarSearchWidget(
    //         ["Pizza", "Coke", "Pumpkin", "Carrot", "Mango"]));
    // print("The searched result is now this $result");
  }


  String getImageUrlFromApi(String rawUrl) {
    return "https://pbs.twimg.com/media/D1NnSsjXcAAh5bP.jpg";
  }
}
