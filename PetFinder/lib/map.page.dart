import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
  bool streamData;
  var dogNameRef;
  var lastTimeRef;
  var lastDateRef;
  var dateTimeRef;
  var dogIdRef;
  var dogModeLat;
  var dogModeLng;
  var initMapPos = LatLng(46.233832398, 6.053166454);

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
      dateTimeRef = "Data: " + lastDateRef + "\n" + "Hora: " + lastTimeRef;
      dogIdRef = snapshot.value["dog_id"].toString();
    });
  }

  void postData() {}

  @override
  Widget _getFAB() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        // FAB 1
        SpeedDialChild(
            child: Icon(Icons.assignment_turned_in),
            onTap: () {/* do anything */},
            label: 'Modo cachorro',
            labelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontSize: 16.0),
            labelBackgroundColor: Colors.yellow),
        // FAB 2
        SpeedDialChild(
          child: Icon(Icons.assignment_turned_in),
          onTap: () {
            setState(() {
              markers.clear();
            });
            streamData = false;
            print("Stream stopped");
          },
          label: 'Parar o rastreamento',
          labelStyle: TextStyle(
              fontWeight: FontWeight.w500, color: Colors.white, fontSize: 16.0),
          labelBackgroundColor: Colors.yellow,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    readData();
    return Scaffold(
        appBar: AppBar(
          title: TextField(
              decoration: new InputDecoration.collapsed(
                  hintText: 'Insira o nome do seu dog aqui!!!'),
              onSubmitted: (val) async {
                if (val == dogNameRef) {
                  streamData = true;
                  while (streamData == true) {
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
                    await Future.delayed(Duration(seconds: 5));
                    setState(() {
                      markers.clear();
                    });
                  }
                } else {
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
              target: initMapPos,
              zoom: 10.0,
            ),
            markers: markers,
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: _getFAB(),
        ));
  }
}

// onPressed: () {
//   setState(() {
//     markers.clear();
//   });
//   streamData = false;
//   print("Stream stopped");
// },
