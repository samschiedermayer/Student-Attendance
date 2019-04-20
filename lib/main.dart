import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:student_attendance/attendance_data.dart';
import 'package:student_attendance/db.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

String userId;

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
  AttendanceData _employeeData; //stores data on employee that will be encoded later
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
    if(_dbInitialized && _shouldUpdate) {
      _generateQRData();
    }

    //output key structure of UI
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('Your Student Code',style: new TextStyle(fontSize: 32.0,fontWeight: FontWeight.bold),),
              ),
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),

                  child: _employeeData!=null ? new QrImage(
                    data: _employeeData.toString(),
                    size: 300,
                  ) : FlutterLogo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //function for getting the data from internal database and location services
  //encodes data into a new EmployeeData object so that the QR code can have accurate data
  void _generateQRData() {
    Future<List<Map<String,dynamic>>> dbData = DB.rawQuery('userData');

    _geolocator = Geolocator();

    Future<GeolocationStatus> locationStatus = _geolocator.checkGeolocationPermissionStatus();
    locationStatus.then((status) async {
      switch(status) {
        case GeolocationStatus.granted:
          Future<Position> position = _geolocator.getCurrentPosition();
          position.then((pos) {
//            print('Position is: $pos');
            dbData.then((queryData) {

              String name;

              for(Map<String, dynamic> map in queryData) {
                map.forEach((k,v) {
                  if (k == "userId") {
                    userId = v;
                  } else if (k == "name") {
                    name = v;
                  }
                });
              }
              if(userId!=null) {
                name = name == null ? "guest" : name;
                setState(() {
                  _employeeData = new AttendanceData(pos.latitude, pos.longitude, new DateTime.now().millisecondsSinceEpoch, userId, name);
                });
                _timer = new Timer(const Duration(seconds: _updateInterval), () {
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
          Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.location]);
          setState(() {});
          print('Unable to access location services with error type: $status');
      }
    });
  }

  //If the user has not entered their userId or name, they will have a pop up prompt them to enter it
  Future _promptForUserData() async {

    final uIdTextController = TextEditingController();
    final nameTextController = TextEditingController();

    await showDialog(
        context: context,
        child: new AlertDialog(
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: Column(
                    children: <Widget>[
                      new TextField(
                        autofocus: true,
                        decoration: new InputDecoration(
                          labelText: 'Employee ID',
                          hintText: 'Enter Employee ID Here',
                        ),
                        controller: uIdTextController,
                      ),
                      new TextField(
                        autofocus: false,
                        decoration: new InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter Name Here',
                        ),
                        controller: nameTextController,
                      ),
                    ],
                  )),
            ],
          ),
          actions: <Widget>[
            new FlatButton(
                child: const Text('SUBMIT'),
                onPressed: () {
                  _commitUserInfo(uIdTextController.text, nameTextController.text);
                  uIdTextController.dispose();
                  nameTextController.dispose();
                  Navigator.pop(context);
                  setState(() {});
                })
          ],
        ));
  }

  //add user information to the database for later usage of the app
  void _commitUserInfo(String uId, String name) {
    DB.insert("UserData", [uId,name]);
  }

}
