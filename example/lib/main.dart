import 'dart:ui';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_sheet/map_sheet.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage2(),
    );
  }
}

class HomePage2 extends StatefulWidget {
  const HomePage2({Key? key}) : super(key: key);

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState $state");
  }

  StateSetter? headerState;
  MapSheetController sheetController = MapSheetController();

  Simulation? createSimulation(ScrollMetrics position, double velocity,
      SpringDescription spring, Tolerance tolerance) {
    /**
        - Range > d1 : if finalX > d1 => jump to d2, else, jump to d1
        - Range d1 -> d2 : if v > 0 => jump to d1, else, jump to d2
        - Range < d2 : jump to d3
     */
    spring = SpringDescription.withDampingRatio(
      mass: 0.5,
      stiffness: 150.0,
      ratio: 1.0,
    );
    double d1 = 0;
    double d2 = -400;
    double d3 = -500;
    final frictionSimulation =
        FrictionSimulation(0.135, position.pixels, velocity);
    final scrollPosition = position.pixels;
    final finalX = frictionSimulation.finalX;
    print("createSimulation p=$scrollPosition v=$velocity vt${tolerance.velocity}");

    if (scrollPosition >= d1) {
      if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
        return BouncingScrollSimulation(
          spring: spring,
          position: position.pixels,
          velocity: velocity,
          leadingExtent: position.minScrollExtent,
          trailingExtent: position.maxScrollExtent,
          tolerance: tolerance,
        );
      }
      print('null Simulation');
      return null;
      if (finalX > d1) {
        return FrictionScrollSimulation(
          spring: spring,
          position: scrollPosition,
          velocity: velocity,
          // trong khoảng trailingExtent -> leadingExtent dùng internal friction
          // ngoài khoảng -> spring về leadingExtent/trailingExtent
          // ScrollSpringSimulation(spring, x, leadingExtent, dx);
          //                               cur, destination,         v
          minPosition: d1,
          maxPosition: position.maxScrollExtent,
          tolerance: tolerance,
          frictionSimulation: frictionSimulation,
        );
      } else {
        // scroll to d2
        if (finalX > d2) {
          return FrictionScrollSimulation(
            spring: spring,
            position: scrollPosition,
            velocity: velocity,
            minPosition: d1,
            maxPosition: position.maxScrollExtent,
            tolerance: tolerance,
            frictionSimulation: frictionSimulation,
          );
        }
        return SpringScrollSimulation(
          spring: spring,
          position: scrollPosition,
          velocity: velocity,
          tolerance: tolerance,
          destination: d2,
        );
      }
    } else if (scrollPosition >= d2) {
      if (velocity == 0 &&
          (scrollPosition == d2 || scrollPosition == d1)) {
        print('null Simulation');
        return null;
      }
      double destination;
      if (velocity == 0) {
        destination = (finalX < (d1 + d2) / 2) ? d2 : d1;
      } else if (velocity < 0) {
        destination = d2;
      } else {
        destination = d1;
      }
      return SpringScrollSimulation(
        spring: spring,
        position: scrollPosition,
        velocity: velocity,
        tolerance: tolerance,
        destination: destination,
      );
    } else {
      if (velocity.abs() < tolerance.velocity && scrollPosition == d3) {
        print('null Simulation');
        return null;
      }
      double destination;
      if (velocity > 0) {
        destination = d1;
      } else {
        destination = d3;
      }
      return SpringScrollSimulation(
        spring: spring,
        position: scrollPosition,
        velocity: velocity,
        tolerance: tolerance,
        destination: destination,
      );
    }
    return null;
  }

  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: LayoutBuilder(builder: (context, size) {
        print('size $size');
        return Stack(
          children: [
            MapSheet(
              child: GoogleMap(
                zoomControlsEnabled: false,
                mapType: MapType.hybrid,
                initialCameraPosition:  CameraPosition(
                  target: LatLng(37.424294, -122.087479),
                  zoom: 14.4746,
                ),
                onMapCreated: (GoogleMapController controller) {
                },
              ),
              backgroundBuilder: (_) {
                return Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Placeholder());
              },
              simulationBuilder: createSimulation,
              slivers: buildSlivers(),
              sheetController: sheetController,
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          sheetController.animateToPosition(target: -250);
        },
      ),
    );
  }

  List<Widget> buildSlivers() {
    return [
      SliverClip(
        child: SliverToBoxAdapter(
          child: GestureDetector(
              onTap: () {
                sheetController.animateToPosition(target: -100);
              },
              child: GrabbingWidget()),
        ),
      ),
      SliverClip(
        child: SliverToBoxAdapter(
          child: SizedBox(
            height: 200,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  return SizedBox(
                      width: 200,
                      child: ListItemWidget());
                }),
          ),
        ),
      ),
      SliverClip(
        child: SliverList(
            delegate:
            SliverChildBuilderDelegate((context, index) {
              return Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: InkWell(
                    onTap: () {
                      print("Click Item");
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("Click ${index}"),
                        duration: Duration(milliseconds: 200),
                      ));
                    },
                    child: Container(
                      color: Colors.green.withOpacity(0.3),
                      width: double.infinity,
                      child: Stack(
                        children: [
                          ListItemWidget(),
                          Center(
                            child: Text('$index'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }, childCount: 30)),
      ),
    ];
  }
}

class GrabbingWidget extends StatelessWidget {
  const GrabbingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,//Color(0xFF0F0F0F),
        // color: Colors.red,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
                color: Colors.white60,
                borderRadius: BorderRadius.circular(100)),
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 15),
                child: Text(
                  "Bình luận",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Text(
                  "48",
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.menu_sharp,
                size: 26,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
          Container(
            color: const Color(0xFF292929),
            width: double.infinity,
            height: 1,
          ),
        ],
      ),
    );
  }
}


class ListItemWidget extends StatelessWidget {
  const ListItemWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F0F0F),
      child: InkWell(
        onTap: () {

        },
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.only(top: 12, bottom: 0, left: 10, right: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 5, right: 10),
                child: true ? const SizedBox() : ClipOval(
                  child: Image.network(
                    "https://yt3.ggpht.com/yti/AJo0G0kUnHqoybmWPJG4GNm0G-lfCiCPbEP62v5tq9PZsA=s48-c-k-c0x00ffffff-no-rj",
                    width: 25,
                    height: 25,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Andrea Quintanilla * 3 tháng trước',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFAEAEAE)),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        'Que buen trabajo, que buenos enganches, genial!!!!  MTV la tenes adentro, jajaja. Saludos cordiales desde Buenos Aires, Argentina, Argentina, Argentina!',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFF6F6F6)),
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(
                          Icons.thumb_up_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        Padding(
                          padding:
                          EdgeInsets.only(left: 16.0, right: 16.0),
                          child: Icon(
                            Icons.thumb_down_alt_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                        Icon(
                          Icons.comment_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}