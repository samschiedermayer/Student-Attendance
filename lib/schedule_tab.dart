import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_attendance/db.dart';
import 'package:student_attendance/schedule_item.dart';

class ScheduleTab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScheduleTabState();

}

class _ScheduleTabState extends State<ScheduleTab> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance.collection('schedule').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return _buildScheduleList(context, snapshot.data.documents);
        },
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
          if (DB.initialized) {
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
      if (DB.initialized) {
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
          color: Theme.of(context).accentColor,
        ),
        child: ListTile(
          title: Text(name),
          trailing: Text(startTime + " until " + endTime),
        ),
      ),
    );
  }
}