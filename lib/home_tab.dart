import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:student_attendance/attendance_data.dart';
import 'package:student_attendance/db.dart';

String userId, name;

class HomeTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Geolocator _geolocator; //used for getting user location
  AttendanceData _studentData; //stores data on student
  bool _shouldUpdate = true;

  static const NOT_LOADED = 0, LOADING = 1, LOADED = 2;
  int _loadingState = LOADING;

  // ignore: unused_field
  Timer _timer;
  static const _updateInterval = 4;

  static const textShadow = [
    Shadow(
        offset: Offset(1.0, 1.0),
        blurRadius: 1.0,
        color: Colors.black26),
    Shadow(
        offset: Offset(2.0, 2.0),
        blurRadius: 1.0,
        color: Colors.black12)
  ];

  @override
  Widget build(BuildContext context) {
    //update QR code if the database is good to go and it is a time that it needs to update
    if (DB.initialized && _shouldUpdate) {
      _generateQRData();
    }

    if(_studentData!=null) _loadingState = LOADED;

    switch (_loadingState) {
      case NOT_LOADED:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('You Need to Sign in',
                  style: new TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      shadows: textShadow)),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: RaisedButton(
                  onPressed: _promptForUserData,
                  child: const Text('Sign in'),
                  color: Theme.of(context).accentColor,
                  elevation: 8.0,
                  splashColor: Colors.grey,
                ),
              ),
            ],
          ),
        );
        break;
      case LOADING:
        return LinearProgressIndicator();
        break;
      case LOADED:
        return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: Text(
                    'Hello, $name',
                    style: new TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        shadows: textShadow),
                  ),
                ),
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: new QrImage(
                      data: _studentData.convert(),
                      size: 300,
                    ),
                  ),
                ),
              ]),
        );
        break;
    }
  }

  //function for getting the data from internal database and location services
  //encodes data into a new EmployeeData object so that the QR code can have accurate data

  bool _promptOS = false;
  void _generateQRData() {
    Future<List<Map<String, dynamic>>> dbData = DB.rawQuery('userData');

    _geolocator = Geolocator();

    Future<GeolocationStatus> locationStatus =
        _geolocator.checkGeolocationPermissionStatus();
    locationStatus.then((status) async {
      switch (status) {
        case GeolocationStatus.granted:
          Future<Position> position = _geolocator.getCurrentPosition();
          position.then((pos) {
//            print('Position is: $pos');
            dbData.then((queryData) {
              for (Map<String, dynamic> map in queryData) {
                map.forEach((k, v) {
                  if (k == "userId") {
                    userId = v;
                  } else if (k == "name") {
                    name = v;
                  }
                });
              }
              if (userId != null) {
                name = name == null ? "guest" : name;
                setState(() {
                  _studentData = new AttendanceData(pos.latitude, pos.longitude,
                      new DateTime.now().millisecondsSinceEpoch, userId, name);
                  _loadingState = LOADED;
                });
                _timer =
                    new Timer(const Duration(seconds: _updateInterval), () {
                  setState(() {
                    _shouldUpdate = true;
                  });
                });
                _shouldUpdate = false;
              } else {
                if(!_promptOS)
                  setState(() {
                    _loadingState = NOT_LOADED;
                    _promptOS = true;
                  });
                _promptForUserData();
                print("Error! userId is null");
              }
            });
          });
          break;
        default:
          //This state will be triggered in any instance where the user has not given the application permission to access location
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
          setState(() {});
          print('Unable to access location services with error type: $status');
      }
    });
  }

  //If the user has not entered their userId or name, they will have a pop up prompt them to enter it
  Future _promptForUserData() async {
    final uIdTextController = TextEditingController();

    await showDialog(
        context: context,
        child: new AlertDialog(
          content: new Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      new TextField(
                        autofocus: true,
                        decoration: new InputDecoration(
                          labelText: 'Student ID',
                          hintText: 'Enter Student ID Here',
                        ),
                        controller: uIdTextController,
                      ),
                    ],
                  ),
                  height: 72,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('SUBMIT'),
                onPressed: () async {
                  print("inside onPressed");
                  bool isValid = await _verifyUserInfo(uIdTextController.text);
                  if (isValid) {
                    uIdTextController.dispose();
                    Navigator.pop(context);
                    Navigator.pop(context);
                    setState(() {});
                  } else {
                    await showDialog(
                        context: context,
                        child: AlertDialog(
                          content: Container(
                            child: Column(
                              children: <Widget>[
                                new Text("Invalid Credentials"),
                              ],
                            ),
                            height: 64,
                          ),
                          actions: <Widget>[
                            new FlatButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'))
                          ],
                        ));
                  }
                })
          ],
        ));
  }

  Future<bool> _verifyUserInfo(String uId) async {
    Future<QuerySnapshot> docs =
        Firestore.instance.collection('users').getDocuments();
    var completer = new Completer<bool>();
    await docs.then((snapshot) {
      bool foundOne = false;
      snapshot.documents.forEach((document) {
        bool uIdMatches = false, canRegister = false;
        String name;
        document.data.forEach((k, v) {
          print("$k,$v");
          switch (k) {
            case "name":
              name = v;
              break;
            case "uId":
              if (v == uId) uIdMatches = true;
              break;
            case "registered":
              if (!v) canRegister = true;
              break;
            default:
              print("Invalid key: $k");
          }
        });
        if (uIdMatches && canRegister) {
          _commitUserInfo(uId, name);
          completer.complete(true);
          foundOne = true;
          var data = document.data;
          data.update("registered", (d) => true);
          Firestore.instance.runTransaction((transaction) async {
            await transaction.update(document.reference, data);
          });
        }
      });
      if (!foundOne) completer.complete(false);
    });
    return completer.future;
  }

  //add user information to the database for later usage of the app
  void _commitUserInfo(String uId, String name) {
    DB.insert("UserData", [uId, name]);
  }
}
