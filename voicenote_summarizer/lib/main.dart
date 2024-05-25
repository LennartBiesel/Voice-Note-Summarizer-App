import 'package:flutter/material.dart';
import 'dart:async';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentSubscription;
  final List<SharedMediaFile> _sharedFiles = [];
  String _transcription = '';
  String _gptResponse = '';

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        print("Shared Files: ${_sharedFiles.map((f) => f.toMap())}");
        if (_sharedFiles.isNotEmpty) {
          sendAudioForTranscription(_sharedFiles.first.path).then((response) {
            setState(() {
              _transcription = response['transcript'] ?? 'No transcription available';
              _gptResponse = response['gpt_response'] ?? 'No GPT response available';
            });
          });
        }
      });
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      setState(() {
        _sharedFiles.clear();
        _sharedFiles.addAll(value);
        print("Initial Shared Files: ${_sharedFiles.map((f) => f.toMap())}");
        if (_sharedFiles.isNotEmpty) {
          sendAudioForTranscription(_sharedFiles.first.path).then((response) {
            setState(() {
              _transcription = response['transcript'] ?? 'No transcription available';
              _gptResponse = response['gpt_response'] ?? 'No GPT response available';
            });
          });
        }

        // Tell the library that we are done processing the intent.
        ReceiveSharingIntent.instance.reset();
      });
    });
  }

  Future<Map<String, String?>> sendAudioForTranscription(String filePath) async {
    var uri = Uri.parse('http://192.168.2.34:5000/transcribe');  // Updated to correct server IP if you wnat to run it anywhere but local 
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return {'transcript': data['transcript'], 'gpt_response': data['gpt_response']};
    } else {
      return {'transcript': 'Error in transcription: ${response.statusCode}', 'gpt_response': null};
    }
  }

  @override
  void dispose() {
    _intentSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: TextTheme(
          bodyText2: TextStyle(color: Colors.black54),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Voice Note Summarizer'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Shared files:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                ..._sharedFiles.map((f) => Text(f.path)).toList(),
                SizedBox(height: 20),
                Text(
                  "Transcription:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_transcription, style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "GPT Response:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Container(
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_gptResponse, style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
