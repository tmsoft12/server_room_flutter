import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'login_page.dart';
import 'settings_page.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late IOWebSocketChannel channel;
  String? doorStatus = 'Ýüklenýär';
  String? fireStatus = 'Ýüklenýär';
  String? pirStatus = 'Ýüklenýär';
  String? tempStatus = 'Ýüklenýär';
  String? humStatus = 'Ýüklenýär';
  bool isConnected = false;
  String _serverIP = '192.168.100.191';
  String _serverPort = '3000';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initNotifications();
    _loadSettings().then((_) {
      initWebSocket();
    });
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverIP = prefs.getString('serverIP') ?? '192.168.100.191';
      _serverPort = prefs.getString('serverPort') ?? '3000';
    });
  }

  void initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Ensure this icon exists

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tmsfot12',
      'Akylly server otagy',
      channelDescription: 'bildirisleri sazla',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: 'app_icon', // Ensure this icon exists
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  void initWebSocket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      connectWebSocket(token);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  void connectWebSocket(String token) {
    channel = IOWebSocketChannel.connect(
      'ws://$_serverIP:$_serverPort/ws',
      headers: {'Authorization': 'Bearer $token'},
    );

    channel.stream.listen(
      (data) {
        setState(() {
          final parsedData = parseWebSocketData(data);
          if (parsedData['door'] != doorStatus) {
            showNotification('Gapy: ', '${parsedData['door']}');
            doorStatus = parsedData['door'];
          }
          if (parsedData['fire'] != fireStatus) {
            showNotification('Yangyn: ', '${parsedData['fire']}');
            fireStatus = parsedData['fire'];
          }
          if (parsedData['pir'] != pirStatus) {
            showNotification('Hereket: ', '${parsedData['pir']}');
            pirStatus = parsedData['pir'];
          }
          tempStatus = parsedData['temp'];
          humStatus = parsedData['hum'];
        });
      },
      onError: (error) {
        reconnectWebSocket();
      },
      onDone: () {
        reconnectWebSocket();
      },
      cancelOnError: true,
    );

    setState(() {
      isConnected = true;
    });
  }

  void reconnectWebSocket() {
    setState(() {
      isConnected = false;
    });

    Future.delayed(Duration(seconds: 5), () {
      if (!isConnected) {
        initWebSocket();
      }
    });
  }

  Map<String, String> parseWebSocketData(dynamic data) {
    final parsedData = <String, String>{};

    try {
      final jsonData = jsonDecode(data);
      parsedData['door'] = jsonData['door'] ?? 'Bilinmeýär';
      parsedData['fire'] = jsonData['fire'] ?? 'Bilinmeýär';
      parsedData['pir'] = jsonData['pir'] ?? 'Bilinmeýär';
      parsedData['temp'] = jsonData['temp'] ?? 'Bilinmeýär';
      parsedData['hum'] = jsonData['hum'] ?? 'Bilinmeýär';
    } catch (e) {
      // Handle parsing error if needed
    }

    return parsedData;
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Esasy Sahypa',
            style: TextStyle(color: Colors.grey[600], fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.grey[600],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.grey[600],
            ),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildCard(
                icon: Icons.thermostat,
                iconColor: Color.fromARGB(255, 255, 0, 0),
                title: 'Tempratura',
                status: tempStatus,
              ),
              buildCard(
                icon: Icons.water_damage,
                iconColor: Color.fromARGB(255, 0, 140, 255),
                title: 'Çyglylyk',
                status: humStatus,
              ),
              buildCard(
                icon: Icons.door_front_door,
                iconColor: Color.fromARGB(202, 204, 153, 0),
                title: 'Gapy',
                status: doorStatus,
              ),
              buildCard(
                icon: Icons.fire_extinguisher,
                iconColor: Colors.red,
                title: 'Yangyn',
                status: fireStatus,
              ),
              buildCard(
                icon: Icons.sensors,
                iconColor: Color.fromARGB(255, 0, 255, 4),
                title: 'Hereket',
                status: pirStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String? status,
  }) {
    return Card(
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          leading: Icon(icon, color: iconColor, size: 40),
          title: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Ýagdaýy: $status',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}
