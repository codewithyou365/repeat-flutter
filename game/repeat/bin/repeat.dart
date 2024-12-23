import 'dart:convert';
import 'dart:io';
import 'package:repeat/common/string_util.dart';
import 'package:repeat/common/ws/client.dart';
import 'package:repeat/common/ws/message.dart';
import 'package:repeat/common/ws/server.dart';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

void main() async {
  final db = sqlite3.open('app_database.db');
  db.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)');

  db.execute('BEGIN TRANSACTION;');
  db.execute('INSERT INTO users (name, age) VALUES ("Alice", 30)');
  db.execute('INSERT INTO users (name, age) VALUES ("Alice", 31)');
  db.execute('COMMIT;');

  final result = db.select('SELECT * FROM users');
  for (final row in result) {
    print('User: id=${row['id']}, name=${row['name']}, age=${row['age']}');
  }

  db.dispose();
}

String replaceChar = '_';

String processWord(String input, String display, String original) {
  List<String> inputSegments = StringUtil.fields(input);
  List<String> originalFields = StringUtil.fields(original);
  List<String> displayFields = StringUtil.fields(display);
  if (inputSegments.isEmpty) {
    return display;
  }
  for (int i = 0; i < originalFields.length; i++) {
    if (inputSegments.isNotEmpty) {
      var rawDisplay = displayFields[i];
      displayFields[i] = processChar(inputSegments[0], displayFields[i], originalFields[i]);
      if (displayFields[i] != rawDisplay) {
        inputSegments.removeAt(0);
        if (inputSegments.isEmpty) {
          break;
        }
      }
    }
  }

  return displayFields.join(' ');
}

String processChar(String input, String currentDisplay, String original) {
  return innerProcessChar(input.split(''), currentDisplay, original);
}

String innerProcessChar(List<String> inputChars, String currentDisplay, String original) {
  List<String> originalChars = original.split('');
  List<String> displayChars = currentDisplay.isEmpty ? List.filled(original.length, replaceChar) : currentDisplay.split('');

  for (int i = 0; i < originalChars.length; i++) {
    if (inputChars.isNotEmpty && originalChars[i].toLowerCase() == inputChars.first.toLowerCase()) {
      displayChars[i] = originalChars[i];
      inputChars.removeAt(0);
    }
  }

  currentDisplay = displayChars.join('');
  return currentDisplay;
}

void main2() {
  // Prompt the user for input
  //String original = "This is an apple.";
  String original = "A sample command-line application with an entrypoint in `bin/`, library code.";
  String currentDisplay = "";
  currentDisplay = processChar(original.replaceAll(RegExp(r'[\p{L}\p{N}]+', unicode: true), ''), currentDisplay, original);
  print(currentDisplay);
  var count = 100;
  while (true) {
    stdout.write('Enter: ');
    String? input = stdin.readLineSync();
    if (input == null || input.isEmpty) {
      continue;
    }
    currentDisplay = processWord(input, currentDisplay, original);
    print(currentDisplay);
    count--;
    if (currentDisplay == original) {
      print("You win!");
      break;
    }
    if (count == 0) {
      print("You lose!");
      break;
    }
  }
}

void main1() async {
  final receivePort = ReceivePort();
  Server s = Server();
  s.start(8089);
  await Isolate.spawn(worker, [receivePort.sendPort]);
}

void worker(List args) async {
  Client client = Client();
  await client.start("ws://127.0.0.1:8089");
  var count = 0;
  while (true) {
    count++;
    Request request = Request(data: "hello");
    print("request: ${jsonEncode(request.toJson())}");
    var response = await client.send(request);
    print("response: ${jsonEncode(response?.toJson())}");
    print("");
    if (count == 5) {
      client.stop();
    }
    if (count == 10) {
      client.start("ws://127.0.0.1:8089");
    }
    await Future.delayed(Duration(seconds: 1));
  }
}
