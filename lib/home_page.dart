import 'dart:developer';
import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pie_chart/pie_chart.dart';
// import 'package:readsms/readsms.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // final _plugin = Readsms();
  Map<String, double> dataMap = {
    "Expense": 1,
    "Earnings": 3,
    // "Xamarin": 2,
    // "Ionic": 2,
  };
  List<SmsMessage> _messages = [];
  @override
  void initState() {
    super.initState();
    getPermission().then((val) {
      log("sms permission" + val.toString());
      getMassage();
    });
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   _plugin.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    // todayExpense();
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          title: const Text("Total Expense"),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height - kToolbarHeight,
          child: Column(
            children: [
              Container(
                // color: Colors.red,
                height: 50,
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      timeButton("Today"),
                      timeButton("Last 5 days"),
                      timeButton("Last 10 days"),
                      timeButton("Last 15 days"),
                      timeButton("Last 20 days"),
                    ],
                  ),
                ),
              ),
              Container(
                height: 200,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                        child: Container(
                      child: PieChart(dataMap: dataMap),
                    )),
                  ],
                ),
              ),
              Container(
                height: 100,
                width: double.maxFinite,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Expanded(
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(color: Colors.blue),
                          child: Center(
                            child: Text(
                              "Total Expense : ",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: double.infinity,
                        decoration: BoxDecoration(color: Colors.blue),
                        child: Center(
                          child: Text(
                            "Total Earnings : ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Details",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                color: Colors.grey,
                height: 2,
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, count) {
                      if (_messages.isEmpty) {
                        return const CircularProgressIndicator(
                          color: Colors.amber,
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          color: Colors.amber,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_messages[count].address!),
                              Text(_messages[count].body!),
                              // Text(_messages[count].sender!),
                              Text(_messages[count].dateSent!.toString()),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ],
          ),
        ));
  }

  Widget timeButton(String title) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(7)),
      child: Container(
        child: Text(title),
      ),
    );
  }

  getMassage() async {
    final SmsQuery _query = SmsQuery();
    List<SmsMessage> Allmessages = await _query.getAllSms;
    List<SmsMessage> messages = [];
    double count = 0;
    double totalExpense = 0;
    double totalEarning = 0;
    double todayExpense = 0;
    for (var SmsMessage in Allmessages) {
      var formatter = DateFormat('yyyy-MM-dd');
      String date = formatter.format(SmsMessage.date!);
      String todayDate = formatter.format(DateTime.now());
      if (date == todayDate && SmsMessage.body!.contains("debited")) {
        todayExpense = todayExpense + getRs(SmsMessage);
      }

      if (SmsMessage.address!.contains("NSDLPB")) {
        if (SmsMessage.body!.contains("debited")) {
          totalExpense = totalExpense + getRs(SmsMessage);
        } else if (SmsMessage.body!.contains("credited")) {
          totalEarning = totalEarning + getRs(SmsMessage);
        }
        messages.add(SmsMessage);
      }
      log(SmsMessage.date.toString());
      count = count + getRs(SmsMessage);
    }
    log(todayExpense.toString());

    log(count.round().toString());
    log(totalEarning.round().toString());
    log(totalExpense.round().toString());
    // return _messages;
    setState(() {
      _messages = messages;
    });
  }

  void todayExpense(SmsMessage SmsMessage) {
    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    String toDayFormattedDate = formatter.format(now);
    String todayExpenseFormattedDate = formatter.format(SmsMessage.date!);
    // print(formattedDate);
    // log(today.toString());
  }

  Future<bool> getPermission() async {
    if (await Permission.sms.status == PermissionStatus.granted) {
      return true;
    } else {
      if (await Permission.sms.request() == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  double getRs(SmsMessage SmsMessage) {
    RegExp regExp = RegExp(r"Rs\.(\d+\.\d+)");
    Match? match = regExp.firstMatch(SmsMessage.body!);
    // log(match.groups(1).toString());
    // count = count + int.parse(match.group(1)!);

    if (match != null) {
      return double.parse(match.group(1)!);
    }

    return 0;
  }
}
