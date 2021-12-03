import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:starflut/starflut.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TextToSpeech(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TextToSpeech extends StatefulWidget {
  const TextToSpeech({Key? key}) : super(key: key);

  @override
  _TextToSpeechState createState() => _TextToSpeechState();
}

class _TextToSpeechState extends State<TextToSpeech> {
  bool isSpeaking = false;
  final TextEditingController _controller = TextEditingController();
  final _flutterTts = FlutterTts();

  bool _buttonPressed = false;
  bool _loopActive = false;

  void initializeTts() {
    _flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });
    _flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });
    _flutterTts.setErrorHandler((message) {
      setState(() {
        isSpeaking = false;
      });
    });
  }

  @override
  void initState() {
    
    _flutterTts.setLanguage("ru-RU");
    _flutterTts.awaitSpeakCompletion(true);
    super.initState();
    initializeTts();
  }

  void speakWhilePressed() async {
    if (_loopActive) return;
    _loopActive = true;
    while(_buttonPressed){
      if (!isSpeaking){
        if (_controller.text.isNotEmpty) {
          print(isSpeaking);
          await _flutterTts.speak(_controller.text);
          await Future.delayed(Duration(milliseconds: _controller.text.length * 100), () {
            
          });
          print(_controller.text.length);
        }
      }
    }
    _loopActive = false;
  }

  void speak() async {
    if (_controller.text.isNotEmpty) {
      await _flutterTts.speak(_controller.text);
    }
  }

  void stop() async {
    print('here0');
    await _flutterTts.stop();
    print('here');
    setState(() {
      _loopActive = false;
      isSpeaking = false;
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Text To Speech"),
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            width: double.infinity,
            child: TextField(
              controller: _controller,
            ),
          ),
          // Listener(
          //     onPointerDown: (details) {
          //       _buttonPressed = true;
          //       speakWhilePressed();
          //     },
          //     onPointerUp: (details) {
          //       _buttonPressed = false;
          //     },
          //     child: Container(
          //       decoration: BoxDecoration(color: Colors.orange, border: Border.all()),
          //       padding: EdgeInsets.all(16.0),
          //       child: Text('Anime'),
            // ),
            ElevatedButton(
              onPressed: () async {
                if (_buttonPressed){
                  _buttonPressed = false;
                  stop();
                }else{
                  print('anime');
                  _buttonPressed = true;
                  speakWhilePressed();
                }
              },
              child: Text(_buttonPressed ? "Остановить" : "Произносить"),
          ),
        ],
      ),
    );
  }
}