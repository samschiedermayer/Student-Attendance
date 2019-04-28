import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

//Class full of static methods for dealing with a single database instance
class DB {

  static Database database;

  //deals with all database initialization functions
  //takes an argument of a function to be called when the database
  //has been successfully initialized
  static void initDB(Function success) async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'userInfo.db');

    database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(
              'CREATE TABLE UserData (userId TEXT, name TEXT)');
          await db.execute(
              'CREATE TABLE Schedule (name TEXT, startTime TEXT, endTime TEXT, UNIQUE(name, startTime, endTime))');
        }, onOpen: success);
  }

  //takes the name of a table and returns all items in a list of maps from that table
  static Future<List<Map<String, dynamic>>> rawQuery(String table) async {
    return await database.rawQuery('SELECT * FROM $table');
  }

  //insert multiple objects into a specified table in the database
  static void insert(String table, List<Object> data) async {
    await database.transaction((txn) async {
      String command = 'INSERT OR IGNORE INTO ${table}\n VALUES (';
      for (int i = 0; i < data.length; i++) {
        Object item = data[i];
        if (i != data.length - 1) {
          if (item is String)
            command = command + '"$item", ';
          else
            command = command + '$item, ';
        } else {
          if (item is String)
            command = command + '"$item"';
          else
            command = command + '$item';
        }
      }
      command = command + ')';

      int id = await txn.rawInsert(command);
    });
  }

  static Future clearTable(String table) async {
    await database.transaction((txn) async {
      String command = 'DELETE FROM $table';
      await txn.rawDelete(command);
    });
  }

}