import 'package:meta/meta.dart';

class AttendanceData {
  double latitude, longitude;
  int time;
  String userId, name;

  AttendanceData(this.latitude, this.longitude, this.time, this.userId, this.name);

  AttendanceData.fromString(String parseableData) {

    List<String> data = parseableData.split(",");

    if(data.length!=4) {
      print("AttendanceData: Invalid pareableData");
      return;
    }

    List<String> latLong = data[0].split(" ");
    this.latitude = double.parse(latLong[0]);
    this.longitude = double.parse(latLong[1]);

    this.time = int.parse(data[1]);

    this.userId = data[2];

    this.name = data[3];

  }

  @override
  String toString() {
    return "$latitude $longitude,$time,$userId,$name";
  }

}