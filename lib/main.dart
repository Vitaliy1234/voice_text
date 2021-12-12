import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as imglib;
import 'package:starflut/starflut.dart';
import 'dart:async';
import 'dart:typed_data';

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

  late Image returnedImage;
  bool imageDone = false;

  


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
    returnedImage = await convertYUV420toImageColor(img);
    print(returnedImage);
    print(returnedImage.runtimeType);
    print(returnedImage.toString());
    setState(() {
      imageDone = true;
    });
    to_speech = await pythonScriptRun(returnedImage); //Питон скрипт
    await _flutterTts.speak(to_speech);
    setState(() {
      _buttonPressed = false;
    });
    
  }

  String pythonScriptRun(Image img){
    return 'на картинке аниме';
  }

  final shift = (0xFF << 24);
  Future<Image> convertYUV420toImageColor(CameraImage image) async {
      try {
        final int width = image.width;
        print(image.width);
        print(image.height);
        final int height = image.height;
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel as int;

        print("uvRowStride: " + uvRowStride.toString());
        print("uvPixelStride: " + uvPixelStride.toString());

        // imgLib -> Image package from https://pub.dartlang.org/packages/image
        var img = imglib.Image(width, height); // Create Image buffer

        // Fill image buffer with plane[0] from YUV420_888
        for(int x=0; x < width; x++) {
          for(int y=0; y < height; y++) {
            final int uvIndex = uvPixelStride * (x/2).floor() + uvRowStride*(y/2).floor();
            final int index = y * width + x;

            final yp = image.planes[0].bytes[index];
            final up = image.planes[1].bytes[uvIndex];
            final vp = image.planes[2].bytes[uvIndex];
            // Calculate pixel color
            int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
            int g = (yp - up * 46549 / 131072 + 44 -vp * 93604 / 131072 + 91).round().clamp(0, 255);
            int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);     
            // color: 0x FF  FF  FF  FF 
            //           A   B   G   R
            img.data[index] = shift | (b << 16) | (g << 8) | r;
          }
        }
        print(img.data);
        print(img.length);

        imglib.PngEncoder pngEncoder = new imglib.PngEncoder(level: 0, filter: 0);
        
        List<int> png = pngEncoder.encodeImage(img);
        print(png.length);
        print(png.join(' '));
        bool muteYUVProcessing = false;
        Uint8List uint8List;
        uint8List = Uint8List.fromList(png); 
        print(uint8List);
        return Image.memory(uint8List);  
      } catch (e) {
        print(">>>>>>>>>>>> ERROR:" + e.toString());
      }
      var anime = null;
      throw anime;
  }

  @override
  Widget build(BuildContext context) {
    // final globalKey = GlobalKey<ScaffoldState>();
    // double height_appbar = Scaffold.of(context).appBarMaxHeight as double;
    // double height_full = MediaQuery.of(context).size.height;
    // double width_full = MediaQuery.of(context).size.width;
    // height_full = height_full - height_appbar;


    return Scaffold(
      appBar: AppBar(
        elevation : 0,
        title: Text("Text To Speech"),
        centerTitle: true,
      ),
      // body: Center(
      //     child:Column(children: [(_cameraInitialized)
      //       ? AspectRatio(aspectRatio: 1,
      //           child: CameraPreview(_camera),)
      //       : CircularProgressIndicator(),
      //       (imageDone) ? returnedImage: CircularProgressIndicator()
      //       ],)
        body: Center(
        child:(_cameraInitialized)
          ? AspectRatio(aspectRatio: 0.65,
            child:  CameraPreview(_camera),
      ): CircularProgressIndicator(),
    ) ,

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