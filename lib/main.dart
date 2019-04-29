import 'dart:async';

import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:student_attendance/attendance_data.dart';
import 'package:student_attendance/db.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_attendance/home_tab.dart';
import 'package:student_attendance/news_tab.dart';
import 'package:student_attendance/schedule_item.dart';
import 'package:student_attendance/schedule_tab.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hortonville High School',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  //key function that builds the homescreen widget
  @override
  Widget build(BuildContext context) {
    //initialize the database and pass a function to signal that it is successfully initialized
    DB.initDB((db) {
      print('Successfully initialized db');
      setState(() {
        DB.initialized = true;
      });
    });

    //output key structure of UI
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Hortonville High School'),
        ),
        body: TabBarView(
          children: <Widget>[
            Container(
              color: Colors.grey[100],
//              decoration: BoxDecoration(
//                  gradient: LinearGradient(
//                      begin: Alignment.centerLeft,
//                      end: Alignment.centerRight,
//                      colors: [
//                    Colors.red[300],
//                    Colors.red[400],
//                  ])),
              child: HomeTab(),
            ),
            Container(
              color: Colors.grey[100],
//              decoration: BoxDecoration(
//                  gradient: LinearGradient(
//                      begin: Alignment.centerLeft,
//                      end: Alignment.centerRight,
//                      colors: [
//                    Colors.red[400],
//                    Colors.red[500],
//                  ])),
              child: ScheduleTab(),
            ),
            Container(
              child: NewsTab(),
              color: Colors.grey[100],
//              decoration: BoxDecoration(
//                  gradient: LinearGradient(
//                      begin: Alignment.centerLeft,
//                      end: Alignment.centerRight,
//                      colors: [
//                    Colors.red[500],
//                    Colors.red[600],
//                  ])),
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
          labelColor: Theme.of(context).accentColor,
          unselectedLabelColor: Theme.of(context).buttonColor,
          indicatorSize: TabBarIndicatorSize.label,
          indicatorPadding: EdgeInsets.all(5.0),
          indicatorColor: Theme.of(context).indicatorColor,
        ),
      ),
    );
  }
}
