
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

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

  void goToDestination(String input) async {
    print('Destination submitted: $input');
    
  if (input.isNotEmpty) {
    try {
      List<geocoding.Location> locations =
          await geocoding.locationFromAddress(input);
      if (locations.isNotEmpty) {
        geocoding.Location location = locations.first;
        print('Location found: $location');
        setState(() {
          destinationCoordinates =
              LatLng(location.latitude, location.longitude);
          print('Destination coordinates updated: $destinationCoordinates');
        });

        mapController.animateCamera(CameraUpdate.newLatLngZoom(
            destinationCoordinates, 12.0));
          print('Map updated successfully');
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


  
  Widget buildMap(BuildContext context) {
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
              print('Submitted: $value');
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
              },
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