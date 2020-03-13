import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:sms/sms.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:verbal_expressions/verbal_expressions.dart';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'character_controller.dart';
import 'login_character.dart';
import 'theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // getApi();
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData.dark(),
        home: checkURL());
  }
}

class checkURL extends StatefulWidget {
  final String title;

  const checkURL({Key key, this.title}) : super(key: key);

  @override
  _checkURLState createState() => _checkURLState();
}

class _checkURLState extends State<checkURL> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String checkMsg = "";
  String url = "";
  String message = "Safe";
  Color boxColor = Colors.green;
  final CharacterController _characterController =
      CharacterController(projectGaze: LoginCharacter.projectGaze);

  String _password;

  void receiveMsg() {
    SmsReceiver receiver = SmsReceiver();
    receiver.onSmsReceived.listen((SmsMessage msg) {
      print(msg.body);
      checkLink(msg.body);
    });
  }

  void checkLink(String link) {
    var expression = VerbalExpression()
      ..startOfLine()
      ..then("http")
      ..maybe("s")
      ..then("://")
      ..maybe("www.")
      ..anythingBut(" ")
      ..then(".")
      ..maybe("com")
      ..anythingBut(" ")
      ..endOfLine();

    RegExp regex = expression.toRegExp();

    var match = regex.firstMatch(link);

    if (match != null) {
      print("URL is Valid");
      setState(() {
        checkUrlUsingApi(match.group(0));
      });
    } else {
      print("Enter Valid URL");
    }
  }

  void checkUrlUsingApi(String checkUrl) async {
    // This example uses the Google Books API to search for books about http.
    // https://developers.google.com/books/docs/overview
    var url =
        'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=AIzaSyCdxUuGFD-oxeGx-SXgK4PpgBYsSrp-POs';
    var reqBody = {
      "client": {"clientId": "cybersecurity", "clientVersion": "0.0.1"},
      "threatInfo": {
        "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING"],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [
          {"url": checkUrl},
        ]
      }
    };

    var reqHeaders = {'Content-Type': 'application/json', 'HTTP': '1.1'};

    // Await the http get response, then decode the json-formatted response.
    var response = await http.post(url,
        headers: reqHeaders, body: convert.jsonEncode(reqBody));
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      if (jsonResponse['matches'] != null) {
        print('Data is ${jsonResponse['matches']}');

        // var malwareResponse = jsonResponse['matches'][0];
        // message = malwareResponse['threatType'];
        message = "DANGER";
        boxColor = Colors.red;
        _characterController.lament();
      } else {
        _characterController.rejoice();
        print('No Match Found');
        message = "Link is Secured";
        boxColor = Colors.green;
      }
      setState(() {
        showNotificationWithDefaultSound();
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
      print('Request failed  due to : ${response.body}.');
      message = "Something wrong with request";
    }
  }

  @override
  void initState() {
    super.initState();
//    Notification setting
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    initializeNotification();
    receiveMsg();
  }

  Future initializeNotification() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = IOSInitializationSettings();
    var initSetttings = InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: selectNotification);
  }

  Future selectNotification(String payload) async {
    debugPrint("payload : $payload");
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Message'),
        content: Text('$message'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    EdgeInsets devicePadding = MediaQuery.of(context).padding;
    // checkNotifications();
    return Scaffold(
        backgroundColor: const Color.fromRGBO(255, 0, 255, 1.0),
        body: Container(
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    // Box decoration takes a gradient
                    gradient: LinearGradient(
                      // Where the linear gradient begins and ends
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      // Add one stop for each color. Stops should increase from 0
                      // to 1
                      stops: const [0.0, 1.0],
                      colors: background,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                      left: 20.0, right: 20.0, top: devicePadding.top + 50.0),
                  child: SingleChildScrollView(
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: <Widget>[
                              LoginCharacter(controller: _characterController),
                              Container(
                                decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(cornerRadius))),
                                child: Padding(
                                  padding: const EdgeInsets.all(30.0),
                                  child: Form(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Padding(
                                            padding:
                                                EdgeInsets.only(top: 50.0)),
                                        TextFormField(
                                          decoration: InputDecoration(
                                            labelText: "Enter URL",
                                            labelStyle: TextStyle(
                                                color: Colors.white70),
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25.0),
                                              borderSide: BorderSide(),
                                            ),
                                            //fillColor: Colors.green
                                          ),
                                          onChanged: (context) {
                                            url = context;
                                          },
                                          validator: (val) {
                                            if (val.length == 0) {
                                              return "Email cannot be empty";
                                            } else {
                                              return null;
                                            }
                                          },
                                          keyboardType: TextInputType.url,
                                        ),
                                        SizedBox(
                                          height: 50.0,
                                        ),
                                        RaisedButton(
                                          onPressed: () {
                                            if (url == "") {
                                              print("No URL passed");
                                              url =
                                                  "http://malware.testing.google.test/testing/malware/";
                                            } else {
                                              print("URL passed is $url");
                                            }
                                            setState(() {
                                              checkLink(url);
                                            });
                                          },
                                          child: Text('Check URL',
                                              style: TextStyle(fontSize: 20)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                new BorderRadius.circular(18.0),
                                          ),
                                          padding: EdgeInsets.all(15.0),
                                        ),
                                        SizedBox(
                                          height: 20.0,
                                        ),
                                        Container(
                                          padding: EdgeInsets.all(10.0),
                                          decoration: BoxDecoration(
                                              color: boxColor,
                                              borderRadius: BorderRadius.all(
                                                const Radius.circular(40.0),
                                              )),
                                          constraints: BoxConstraints(
                                              maxHeight: 100.0,
                                              maxWidth: 300.0,
                                              minWidth: 200.0,
                                              minHeight: 50.0),
                                          child: Padding(
                                            padding: const EdgeInsets.all(25.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  message,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 25.0),
                                                ),
                                                // SizedBox(
                                                //   height: 20.0,
                                                // ),
                                                // Text(
                                                //   url == ""
                                                //       ? "No URL Passed"
                                                //       : url,
                                                //   style: TextStyle(
                                                //       color: Colors.white,
                                                //       fontSize: 10.0),
                                                // ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Future showNotificationWithDefaultSound() async {
    print("In notifications function");
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your_channel_id', 'your_channel_name', 'your_channel_description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, 'URL Status', message, platformChannelSpecifics);
  }
}
