import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:student_attendance/attendance_data.dart';
import 'package:student_attendance/db.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_attendance/schedule_item.dart';

void main() => runApp(MyApp());

String userId, name;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Attendance',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: HomeScreen(title: 'Student Attendance'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Geolocator _geolocator; //used for getting user location
  AttendanceData
      _employeeData; //stores data on employee that will be encoded later
  bool _dbInitialized = false, _shouldUpdate = true; //
  Timer _timer;
  static const _updateInterval = 10;

  //key function that builds the homescreen widget
  @override
  Widget build(BuildContext context) {
    //initialize the database and pass a function to signal that it is successfully initialized
    DB.initDB((db) {
      print('Successfully initialized db');
      setState(() {
        _dbInitialized = true;
      });
    });

    //update QR code if the database is good to go and it is a time that it needs to update
    if (_dbInitialized && _shouldUpdate) {
      _generateQRData();
    }

    //output key structure of UI
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: TabBarView(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                    Colors.red[300],
                    Colors.red[400],
                  ])),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _employeeData != null
                      ? <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Your Student Code',
                              style: new TextStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.bold,
                                  shadows: <Shadow>[
                                    Shadow(
                                        offset: Offset(2.0, 2.0),
                                        blurRadius: 1.0,
                                        color: Colors.black26),
                                    Shadow(
                                        offset: Offset(3.0, 3.0),
                                        blurRadius: 1.0,
                                        color: Colors.black12)
                                  ]),
                            ),
                          ),
                          Container(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: new QrImage(
                                data: _employeeData.convert(),
                                size: 300,
                              ),
                            ),
                          ),
                        ]
                      : <Widget>[
                          Text('You Need to Sign in',
                              style: new TextStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.bold,
                                  shadows: <Shadow>[
                                    Shadow(
                                        offset: Offset(2.0, 2.0),
                                        blurRadius: 1.0,
                                        color: Colors.black26),
                                    Shadow(
                                        offset: Offset(3.0, 3.0),
                                        blurRadius: 1.0,
                                        color: Colors.black12)
                                  ])),
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
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                    Colors.red[400],
                    Colors.red[500],
                  ])),
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: Firestore.instance.collection('schedule').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return LinearProgressIndicator();
                    return _buildScheduleList(context, snapshot.data.documents);
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                    Colors.red[500],
                    Colors.red[600],
                  ])),
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          tabs: [
            Tab(
              icon: new Icon(Icons.home),
            ),
            Tab(
              icon: new Icon(Icons.calendar_today),
            ),
            Tab(
              icon: new Icon(Icons.announcement),
            )
          ],
          //TODO FIX THE COLORS FOR THIS SECTION
          labelColor: Colors.yellow,
          unselectedLabelColor: Colors.lightBlueAccent,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: EdgeInsets.all(5.0),
          indicatorColor: Colors.red,
        ),
      ),
    );
  }

  static const NOT_LOADING = 0, LOADING = 1, COMPLETE = 2;
  int _scheduleState = NOT_LOADING;
  var _scheduleItems = new List<ScheduleItem>();

  Widget _buildScheduleList(
      BuildContext context, List<DocumentSnapshot> snapshots) {
    if (snapshots.length == 0) {
      switch (_scheduleState) {
        case NOT_LOADING:
          if (_dbInitialized) {
            var results = DB.rawQuery('Schedule');
            results.then((results) {
              results.forEach((map) {
                print('Inside new map');
                _scheduleItems.add(ScheduleItem.fromMap(map));
              });
              _scheduleState = COMPLETE;
              setState(() {});
            });
            _scheduleState = LOADING;
          }
          return LinearProgressIndicator();
          break;
        case LOADING:
          return LinearProgressIndicator();
          break;

        case COMPLETE:
          if (_scheduleItems.length > 0) {
            return ListView(
              padding: EdgeInsets.all(8.0),
              children: _scheduleItems
                  .map((scheduleItem) =>
                      _buildScheduleItem(context, scheduleItem))
                  .toList(),
            );
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('Schedule Unavailable',
                    style: new TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        shadows: <Shadow>[
                          Shadow(
                              offset: Offset(2.0, 2.0),
                              blurRadius: 1.0,
                              color: Colors.black26),
                          Shadow(
                              offset: Offset(3.0, 3.0),
                              blurRadius: 1.0,
                              color: Colors.black12)
                        ])),
              ),
            );
          }
          break;
      }
    } else {
      if (_dbInitialized) {
        for (var snapshot in snapshots) {
          final record = ScheduleItem.fromSnapshot(snapshot);
          DB.clearTable('Schedule');
          DB.insert(
              'Schedule', [record.name, record.startTime, record.endTime]);
        }
        _scheduleState = NOT_LOADING;
      }
      return ListView(
        padding: EdgeInsets.all(8.0),
        children: snapshots
            .map((data) =>
                _buildScheduleItem(context, ScheduleItem.fromSnapshot(data)))
            .toList(),
      );
    }
  }

  Widget _buildScheduleItem(BuildContext context, ScheduleItem scheduleItem) {
    final String name = scheduleItem.name,
        startTime = scheduleItem.startTime,
        endTime = scheduleItem.endTime;

    return Padding(
      key: ValueKey(name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5.0),
          color: Colors.redAccent[200],
        ),
        child: ListTile(
          title: Text(name),
          trailing: Text(startTime + " until " + endTime),
        ),
      ),
    );
  }

  //function for getting the data from internal database and location services
  //encodes data into a new EmployeeData object so that the QR code can have accurate data
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
                  _employeeData = new AttendanceData(
                      pos.latitude,
                      pos.longitude,
                      new DateTime.now().millisecondsSinceEpoch,
                      userId,
                      name);
                });
                _timer =
                    new Timer(const Duration(seconds: _updateInterval), () {
                  setState(() {
                    _shouldUpdate = true;
                  });
                });
                _shouldUpdate = false;
              } else {
                _promptForUserData();
                print("Error! userId is null");
              }
            });
          });
          break;
        default:
          //This state will be triggered in any instance where the user has not given the application permission to access location
          Map<PermissionGroup, PermissionStatus> permissions =
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
                            height: 72,
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
          //TODO ADD THESE COMMENTED LINES BACK IN!!!!
          //TODO ADD THESE COMMENTED LINES BACK IN!!!!
//          var data = document.data;
//          data.update("registered", (d) => true);
//          Firestore.instance.runTransaction((transaction) async {
//            await transaction.update(document.reference, data);
//          });
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
