import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteGuard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'RouteGuard'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  TextEditingController destinationController = TextEditingController();
  LatLng destinationCoordinates = const LatLng(37.7749, -122.4194);
  LatLng currentLocation = LatLng(37.7749, -122.4194);
  Polyline? _routePolyline;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _getAndDrawRoute(LatLng origin, LatLng destination) async{
  String apiUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=AIzaSyDPgYA8eHy9XlWi-JZHeljffv6dpic6K9A";

  http.Response response = await http.get(Uri.parse(apiUrl));
  Map<String, dynamic> data = jsonDecode(response.body);

  List<LatLng> points = _decodePolyline(data['routes'][0]['overview_polyline']['points']);

  _addPolyline(points);

}

  Future<void> goToDestination(String input) async {
    
  if (input.isNotEmpty) {
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(input);
      if (locations.isNotEmpty) {
        geocoding.Location location = locations.first;
        setState(() {
          destinationCoordinates =
              LatLng(location.latitude, location.longitude);
        });

        mapController.animateCamera(CameraUpdate.newLatLngZoom(
            destinationCoordinates, 12.0));

        _getAndDrawRoute(currentLocation, destinationCoordinates);
      } else {
        // Handle case where no location was found
        print('No location found for the input: $input');
      }
    } catch (e) {
      // Handle any errors that might occur during geocoding
      print('Error geocoding the input: $e');
    }
  } else {
    // Handle case where input is empty
    print('Input is empty');
  }
}



List<LatLng> _decodePolyline(String polyline) {
    var points = <LatLng>[];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }

    return points;
  }

  void _addPolyline(List<LatLng> polylineCoordinates) {
    Polyline newPolyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 3,
    );

    setState(() {
      _routePolyline = newPolyline;
    });

  }

  
  Widget buildMap(BuildContext context) {
    Set<Polyline> polylines = {};
    if(_routePolyline != null) {
      polylines.add(_routePolyline!);
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: destinationController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter the destination',
            ),
            onSubmitted: (value) {
              goToDestination(value);
            },
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController  = controller;
              },
              initialCameraPosition: CameraPosition(
                target: destinationCoordinates,
                zoom: 12.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destinationCoordinates,
                ),
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: currentLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                ),
              },
              polylines: polylines,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return buildMap(context);
  }
}