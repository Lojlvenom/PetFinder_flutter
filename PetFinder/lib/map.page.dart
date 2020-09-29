import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

// init
class _MapPageState extends State<MapPage> {
  DatabaseReference dataRef;
  GoogleMapController mapController;
  Set<Marker> markers = new Set<Marker>();
  var latRef;
  var lngRef;
  bool streamData;
  bool streamDataDog;
  var dogNameRef;
  var lastTimeRef;
  var lastDateRef;
  var dateTimeRef;
  var dogIdRef;
  var dogModeLat;
  var dogModeLng;
  var initMapPos = LatLng(46.233832398, 6.053166454);

// DB AND MAP CONTROLLER

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    dataRef = FirebaseDatabase.instance.reference().child("ShurasteiHash");
    super.initState();
  }

// READ DATA - TRACK MODE

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

// POST DATA - DOG MODE
  void getDogGpsPosition() async {
    final position =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    dogModeLat = position.latitude;
    dogModeLng = position.longitude;
  }

  void postData() {
    DateTime now = new DateTime.now();
    var hourStr = now.hour.toString();
    var minuteStr = now.minute.toString();
    var secStr = now.second.toString();
    var timePayload = hourStr + ":" + minuteStr + ":" + secStr;

    var dayStr = now.day.toString();
    var monStr = now.month.toString();
    var yrStr = now.year.toString();
    var datePayload = dayStr + "/" + monStr + "/" + yrStr;

    dataRef.set({
      'latitude': dogModeLat,
      'longitude': dogModeLng,
      'dog_name': "Shurastei",
      'time': timePayload,
      'date': datePayload,
      'dog_id': '1'
    });
  }

// DIALOGS AND FAB WIDGET

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
              color: Colors.blue,
              textColor: Colors.white,
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

  void _showDialogDog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: new Text('Modo cachorro ativado'),
          content: new Text(
              'Agora você está no modo cachorro, utilize outro celular para consultar a localização.'),
          actions: <Widget>[
            // define os botões na base do dialogo
            new FlatButton(
              color: Colors.red,
              textColor: Colors.white,
              child: new Text("SAIR DO MODO CACHORRO"),
              onPressed: () {
                streamDataDog = false;
                print(" DOG Stream stopped");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _getFAB() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        // FAB 1
        SpeedDialChild(
          child: Icon(Icons.pets),
          onTap: () async {
            streamData = false;
            print("LOCATOR Stream stopped");
            print("DOG Stream start");
            streamDataDog = true;
            _showDialogDog();
            while (streamDataDog == true) {
              getDogGpsPosition();
              postData();
              await Future.delayed(Duration(seconds: 1));
            }
          },
          label: 'Modo cachorro',
          labelStyle: TextStyle(
              fontWeight: FontWeight.w500, color: Colors.white, fontSize: 16.0),
          labelBackgroundColor: Colors.blue,
        ),
        // FAB 2
        SpeedDialChild(
          backgroundColor: Colors.red,
          child: Icon(Icons.warning),
          onTap: () {
            setState(() {
              markers.clear();
            });
            streamData = false;
            print("LOCATOR Stream stopped");
            _showDialog("Rastreamento Interrompido",
                "O rastreamento foi interrompido no momento, para realizar uma nova consulta digite o nome do seu animal na caixa de texto.");
          },
          label: 'Parar o rastreamento',
          labelStyle: TextStyle(
              fontWeight: FontWeight.w500, color: Colors.white, fontSize: 16.0),
          labelBackgroundColor: Colors.red,
        )
      ],
    );
  }

  // MAIN SCAFFOLD

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
                    print("LOCATOR Stream start");
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
                    await Future.delayed(Duration(seconds: 1));
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
