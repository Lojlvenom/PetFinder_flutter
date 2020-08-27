import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  void _showDialog(text1, text2) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: new Text(text1),
          content: new Text(text2),
          actions: <Widget>[
            // define os botões na base do dialogo
            new FlatButton(
              child: new Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  DatabaseReference dataRef;
  GoogleMapController mapController;
  Set<Marker> markers = new Set<Marker>();
  var latRef;
  var lngRef;
  var dogNameRef;
  var lastTimeRef;
  var lastDateRef;
  var dateTimeRef;
  var dogIdRef;
  final snackBar = SnackBar(content: Text('Dog nao encontrado'));
  double lat = 46.233832398;
  double lng = 6.053166454;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    dataRef = FirebaseDatabase.instance.reference().child("ShurasteiHash");
    super.initState();
  }

  void readData() {
    dataRef.once().then((DataSnapshot snapshot) {
      latRef = snapshot.value["latitude"];
      lngRef = snapshot.value["longitude"];
      dogNameRef = snapshot.value["dog_name"];
      lastTimeRef = snapshot.value["time"].toString();
      lastDateRef = snapshot.value["date"].toString();
      dateTimeRef = lastDateRef + "\n" + lastTimeRef;
      dogIdRef = snapshot.value["dog_id"].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    readData();
    return Scaffold(
        appBar: AppBar(
          title: TextField(onSubmitted: (val) {
            if (val == dogNameRef) {
              print(latRef);
              print(lngRef);
              LatLng position = LatLng(latRef, lngRef);
              mapController.moveCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(target: position, zoom: 19.00)));

              final Marker marker = Marker(
                  markerId: new MarkerId(
                      dogIdRef), //criar ID único com localização dinâmica
                  position: position,
                  onTap: () {
                    _showDialog(dogNameRef, dateTimeRef);
                  });
              setState(() {
                markers.add(marker);
              });
            } else {
              print("Dog nao existe");
              _showDialog(
                  "AVISO!", "Esse dog não existe ou não foi cadastrado!");
              setState(() {
                markers.clear();
              });
            }
          }),
        ),
        body: Container(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 10.0,
            ),
            markers: markers,
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 275.0),
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                markers.clear();
              });
            },
          ),
        ));
  }
}
