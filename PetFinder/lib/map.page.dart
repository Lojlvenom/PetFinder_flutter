import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController mapController;
  Set<Marker> markers = new Set<Marker>();
  double lat = -3.09197916667;
  double lng = -60.0164885;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onSubmitted: (val) {
            lat = -3.09197916667; //Inserir lat FIREBASE
            lng = -60.0164885; //Inserir lng FIREBASE

            LatLng position = LatLng(lat, lng);
            mapController.moveCamera(CameraUpdate.newLatLng(position));

            final Marker marker = Marker(
              markerId:
                  new MarkerId("1"), //criar ID único com localização dinâmica
              position: position,
              infoWindow: InfoWindow(
                title: "Cachorro 1", //Passar nome de cachorro do FIREBASE
                snippet: "Hub do Hefesto",
              ),
            );
            setState(() {
              markers.add(marker);
            });
          },
        ),
      ),
      body: Container(
        child: GoogleMap(
          onMapCreated: _onMapCreated,
          onCameraMove: (data) {
            print(data);
          },
          onTap: (position) {
            print(position);
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(lat, lng),
            zoom: 18.0,
          ),
          markers: markers,
        ),
      ),
    );
  }
}
