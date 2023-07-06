import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'consts.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  dynamic lightData, fanData, freezeData;

  @override
  void initState() {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        // get light data
        var url = Uri.https("${host}light.json");
        var response = await http.get(url);
        lightData = jsonDecode(response.body);
        print(lightData);

        // get light data
        url = Uri.https("${host}fan.json");
        response = await http.get(url);
        fanData = jsonDecode(response.body);
        print(fanData);

        // get light data
        url = Uri.https("${host}freeze.json");
        response = await http.get(url);
        freezeData = jsonDecode(response.body);
        print(freezeData);
      } catch (ex) {
        print("no internet!");
      }
    });
    super.initState();
  }

  Future<void> fetchData() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: FutureBuilder(
        future: fetchData(),
        builder: (context, data) {
          if (data.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Column(children: []);
        },
      ),
    );
  }
}
