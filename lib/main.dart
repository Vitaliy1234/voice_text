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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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

  late CameraController _camera;
  bool _cameraInitialized = false;
  late CameraImage _savedImage;

  List<CameraDescription> _cameras = [];
  late CameraController _controller_camera;


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
    super.initState();
    initializeTts();
    _initializeCamera();

    _flutterTts.setLanguage("ru-RU");
    _flutterTts.awaitSpeakCompletion(true);


  }
  // Camera
  Future<CameraDescription> _getCamera(CameraLensDirection dir) async {
    return await availableCameras().then(
      (List<CameraDescription> cameras) => cameras.firstWhere(
            (CameraDescription camera) => camera.lensDirection == dir,
          ),
    );
  }

  void _initializeCamera() async {
    _camera = CameraController(await _getCamera(CameraLensDirection.back),ResolutionPreset.medium);
    _camera.initialize().then((_) async{
    // Start ImageStream
    await _camera.startImageStream((CameraImage image) =>
      _processCameraImage(image));
      setState(() {
        _cameraInitialized = true;
      });
  });
    // _camera.startImageStream((CameraImage image) {
    //   if (_isDetecting) return;
    //   _isDetecting = true;
    //   try {
    //     // await doSomethingWith(image)
    //   } catch (e) {
    //     // await handleExepction(e)
    //   } finally {
    //     _isDetecting = false;
    //   }
    // });
    setState(() {
      
    });
  }

  void _processCameraImage(CameraImage image) async {
  setState(() {
    print('image saved');
    _savedImage = image;
  });
}

  void speakWhilePressed() async {
    if (_loopActive) return;
    _loopActive = true;
    while(_buttonPressed){
      if (!isSpeaking){
        if (_controller.text.isNotEmpty) {
          print(isSpeaking);
          // var text_to_speech = 
          await _flutterTts.speak(_controller.text);
          await Future.delayed(Duration(milliseconds: _controller.text.length * 100), () {
            
          });
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

  void imageToText(CameraImage img) async {
    String to_speech;
    to_speech = await pythonScriptRun(img); //Питон скрипт
    await _flutterTts.speak(to_speech);
    setState(() {
      _buttonPressed = false;
    });
  }

  String pythonScriptRun(CameraImage img){
    return 'на картинке аниме';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Text To Speech"),
      ),
      body: Center(
          child:
            (_cameraInitialized)
            ? AspectRatio(aspectRatio: _camera.value.aspectRatio,
                child: CameraPreview(_camera),)
            : CircularProgressIndicator()
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
            floatingActionButton: FloatingActionButton.extended(
              label: Text(_buttonPressed ? "Остановаить" : "Произнести"),
              icon: Icon(const IconData(61309, fontFamily: 'MaterialIcons')),
              onPressed: () async {
                if (_buttonPressed){
                  // _buttonPressed = false;
                  // stop();
                  return null;
                }else{
                  setState(() {
                    _buttonPressed = true;
                    imageToText(_savedImage);
                  });
                  // speakWhilePressed();
                }
              },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}