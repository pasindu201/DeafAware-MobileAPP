import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with SingleTickerProviderStateMixin {
  late FlutterSoundRecorder _recorder;
  late FlutterSoundPlayer _player;
  late String _filePath;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _predictionResult = "Press the Button to Record";
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initRecorder();
    _initPlayer();
    _requestPermissions();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true); // Create a pulsing effect
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_recorder.isRecording) {
      return; // Avoid starting another recording while one is in progress
    }

    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/temp.wav';

    await _recorder.startRecorder(
      toFile: _filePath,
      codec: Codec.pcm16WAV,
    );

    setState(() {
      _isRecording = true;
      _animationController.forward(); // Start animation
    });

    // Stop recording after 4 seconds
    Future.delayed(Duration(seconds: 4), () async {
      await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _animationController.stop(); // Stop animation
        _animationController.reset();
      });

      await _sendFile(); // Send the recorded file after stopping
    });
  }

  Future<void> _sendFile() async {
    final uri = Uri.parse('http://34.68.222.142:8080/predict?file');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', _filePath));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    final data = jsonDecode(responseBody);
    setState(() {
      String prediction = data["prediction"].toString();
      if (prediction == "0") {
        _predictionResult = 'Ambulance';
      } else if (prediction == "1") {
        _predictionResult = 'Fire truck';
      } else {
        _predictionResult = 'Traffic';
      }
    });
  }

  Future<void> _playRecording() async {
    if (_player.isPlaying) {
      return;
    }

    await _player.startPlayer(
      fromURI: _filePath,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        setState(() {
          _isPlaying = false;
        });
      },
    );

    setState(() {
      _isPlaying = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: _isRecording ? null : _startRecording,
              child: ScaleTransition(
                scale: _animationController,
                child: Icon(
                  Icons.mic,
                  size: 80,
                  color: _isRecording ? Colors.red : Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playRecording,
              child: Text(_isPlaying ? 'Playing...' : 'Play Recording'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 360,
              height: 260,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                color: Color.fromRGBO(224, 224, 224, 1),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Detected Audio",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _predictionResult,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 10),
                      if (_predictionResult == 'Ambulance') 
                        Image.asset('images/ambulance.png', width: 150, height: 150)
                      else if (_predictionResult == 'Fire truck') 
                        Image.asset('images/fire_truck.png', width: 150, height: 150)
                      else if (_predictionResult == 'Traffic') 
                        Image.asset('images/traffic.png', width: 150, height: 150)
                      else 
                        Container(), // Empty container if no image
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
