// ignore_for_file: must_be_immutable, library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(){
  return runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.teal),
        home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<dynamic>> getCards() async {
    var prefs = await SharedPreferences.getInstance();
    List<Widget> cards = [];
    var todo = prefs.getStringList("todo") ?? [];
    for (var jsonStr in todo) {
      var mapObj = jsonDecode(jsonStr);
      var taskDataObj = mapObj['taskData'];
      var taskData = jsonDecode(taskDataObj);
      var title = taskData["title"];
      var due = taskData["due"];
      var detail = taskData["detail"];
      var state = mapObj['state'];
      cards.add(TodoCardWidget(title: title, due: due, detail: detail, state: state));
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My TODO"),
        actions: [
          IconButton(
              onPressed: () {
                SharedPreferences.getInstance().then((prefs) async {
                  await prefs.setStringList("todo", []);
                  setState(() {});
                });
              },
              icon: const Icon(Icons.delete))
        ],
      ),

      body: Center(
        child: FutureBuilder<List>(
          future: getCards(),
          builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Text('Waiting to start');
              case ConnectionState.waiting:
                return const Text('Loading...');
              default:
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return snapshot.data![index];
                      });
                }
            }
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var taskData = await _showTextInputDialog(context);
          if (taskData != null) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            var todo = prefs.getStringList("todo") ?? [];
            var mapObj = {"taskData": taskData, "state": false};
            var jsonStr = jsonEncode(mapObj);
            todo.add(jsonStr);
            await prefs.setStringList("todo", todo);

            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  final _titleController = TextEditingController();
  final _dueController = TextEditingController();
  final _detailController = TextEditingController();

  Future<String?> _showTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('TODO'),
            content: SizedBox(
              height: 160,
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: "タスクの名称"),
                  ),
                  TextField(
                    controller: _dueController,
                    decoration: const InputDecoration(hintText: "期限"),
                  ),
                  TextField(
                    controller: _detailController,
                    decoration: const InputDecoration(hintText: "詳細"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text("キャンセル"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () {
                  var mapObj = {"title": _titleController.text, "due": _dueController.text, "detail": _detailController.text};
                  var jsonStr = jsonEncode(mapObj);
                  Navigator.pop(context, jsonStr);
                }
              ),
            ],
          );
        });
  }
}

class TodoCardWidget extends StatefulWidget {
  final String title;
  final String due;
  final String detail;

  var state = false;

  TodoCardWidget({
    Key? key,
    required this.title,
    required this.due,
    required this.detail,
    required this.state,
  }) : super(key: key);

  @override
  _TodoCardWidgetState createState() => _TodoCardWidgetState();
}

class _TodoCardWidgetState extends State<TodoCardWidget> {
  void _changeState(value) async {
    setState(() {
      widget.state = value ?? false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var todo = prefs.getStringList("todo") ?? [];

    for (int i = 0; i < todo.length; i++) {
      var mapObj = jsonDecode(todo[i]);
      if (mapObj["title"] == widget.title) {
        mapObj["state"] = widget.state;
        todo[i] = jsonEncode(mapObj);
      }
    }
    prefs.setStringList("todo", todo);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 20, top: 30, right: 20),
      child: Container(
        padding: const EdgeInsets.only(left: 30, top: 20, right: 30, bottom: 20),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Checkbox(onChanged: _changeState, value: widget.state),
                  Container(
                    padding: const EdgeInsets.only(left: 5),
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                const Text("期限"),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(widget.due),
                ),

              ],
            ),
            Row(
              children: [
                const Text("詳細"),
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  child: Text(widget.detail),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}