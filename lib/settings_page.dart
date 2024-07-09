import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  String _serverIP = '192.168.100.191';
  String _serverPort = '3000';
  String _currentPhoneNumber = '';
  String _jwtToken = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverIP = prefs.getString('serverIP') ?? '192.168.100.191';
      _serverPort = prefs.getString('serverPort') ?? '3000';
      _jwtToken = prefs.getString('token') ?? '';
    });

    // Fetch current phone number using the fetched token
    await _fetchCurrentPhoneNumber();
  }

  Future<void> _fetchCurrentPhoneNumber() async {
    try {
      final response = await http.get(
        Uri.parse('http://$_serverIP:$_serverPort/phone'),
        headers: <String, String>{
          'Authorization': 'Bearer $_jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          _currentPhoneNumber = jsonData[0][
              'phone']; // Assuming phone number is in the first element of the array
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch current phone number')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch current phone number: $e')),
      );
    }
  }

  Future<void> _updatePhoneNumber(String newPhoneNumber) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http://$_serverIP:$_serverPort/phone/1'), // Statik olarak id: 1
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $_jwtToken',
        },
        body: jsonEncode(<String, String>{
          'phone': newPhoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        // Başarılı güncelleme durumunda
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone number updated successfully')),
        );
      } else {
        // Başarısız durumda
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update phone number: $newPhoneNumber')),
        );
      }
    } catch (e) {
      // Hata durumunda
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update phone number: $newPhoneNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sazlamalar',
            style: TextStyle(
              color: Colors.grey[600],
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server Sazlamalary',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Text('Server IP: $_serverIP'),
            Text('Server Port: $_serverPort'),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Sms Servis belgisi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Text('$_currentPhoneNumber'),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            Text(
              'Sms belgisini sazlamak',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Taze tefon belgisi',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _updatePhoneNumber(_phoneNumberController.text);
              },
              child: Text(
                'Tassyklamak ',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
