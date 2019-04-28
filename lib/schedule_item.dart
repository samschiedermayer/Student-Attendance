import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleItem {
  String name, startTime, endTime;
  final DocumentReference reference;

  ScheduleItem(String name, String startTime, String endTime, this.reference){
    this.name = name;
    this.startTime = startTime;
    this.endTime = endTime;
  }

  ScheduleItem.fromMap(Map<String, dynamic> map, {this.reference})
      : name = map['name'],
        startTime = map['startTime'],
        endTime = map['endTime'];

  ScheduleItem.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  Map<String, dynamic> toMap() {
    return {
      'name' : name,
      'startTime' : startTime,
      'endTime' : endTime
    };
  }

}