import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cara/resturant.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MapsScreen(),
    );
  }
}

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  MapsScreenState createState() => MapsScreenState();
}

class MapsScreenState extends State<MapsScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  List<Restaurant> restaurants = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants Map')),
      body: GoogleMap(
        mapType: MapType.normal,
        myLocationEnabled: true,
        minMaxZoomPreference: const MinMaxZoomPreference(10, 22),
        markers: _restaurantsToMarkerList(restaurants),
        onMapCreated: (controller) {
          _controller.complete(controller);
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(33.9999526, -118.3489043),
          zoom: 13.0,
        ),
        onCameraIdle: () async {
          final controller = await _controller.future;
          final area = await controller.getVisibleRegion();
          final bounds = _getAreaString(area);
          final restaurantsRes = await _fetchRestaurants(bounds);
          setState(() {
            restaurants = restaurantsRes;
          });
        },
      ),
    );
  }

  String _getAreaString(LatLngBounds area) {
    String north = area.northeast.latitude.toStringAsFixed(10);
    String east = area.northeast.longitude.toStringAsFixed(10);
    String south = area.southwest.latitude.toStringAsFixed(10);
    String west = area.southwest.longitude.toStringAsFixed(10);
    return '$west,$south,$east,$north';
  }

  Future<List<Restaurant>> _fetchRestaurants(String bbox) async {
    try {
      const endpoint = 'https://overpass-api.de/api/interpreter';
      final queryParam =
          '?data=[bbox][out:json][timeout:25];(node[amenity=restaurant];);out;&bbox=$bbox';

      var response = await http.get(Uri.parse(endpoint + queryParam));
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
      var osmRestaurants =
          decodedResponse['elements'] as Iterable<dynamic>? ?? [];
      List<Restaurant> restaurants = [];
      for (var element in osmRestaurants) {
        try {
          var restaurant = Restaurant.fromJson(element);
          restaurants.add(restaurant);
          log('Restaurant: ${restaurant.name}, Position: ${restaurant.position}');
        } catch (error) {
          log('Error parsing restaurant data: $error');
        }
      }
      return restaurants;
    } catch (error) {
      log('Error fetching restaurants: $error');
      return [];
    }
  }

  Set<Marker> _restaurantsToMarkerList(List<Restaurant> restaurants) {
    var markerList = restaurants.map((restaurant) {
      return Marker(
        markerId: MarkerId(restaurant.id),
        position: restaurant.position,
        infoWindow: InfoWindow(
          title: restaurant.name,
          snippet: 'Tap for more info',
        ),
      );
    });
    return Set<Marker>.from(markerList);
  }
}
