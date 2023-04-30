import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _result = '';

  late Interpreter _interpreter;

  void loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/yamnet.tflite');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<Float32List> loadWavFile(String filePath) async {
    final FlutterSoundHelper flutterSoundHelper = FlutterSoundHelper();
    final String tempPCMPath = (await getTemporaryDirectory()).path + '/temp.pcm';  
    await flutterSoundHelper.pcmToWave(
      inputFile: filePath,
      outputFile: tempPCMPath,
      sampleRate: 16000,
    );
    final tempPCMFile = File(tempPCMPath);
    final dataBuffer = await tempPCMFile.readAsBytes();
    final data = Float32List.view(dataBuffer.buffer);
    return data;
  }

  List<dynamic> runInference(Float32List input) {
    TensorBuffer outputScores = TensorBuffer.createFixedSize(<int>[1, 521], TfLiteType.float32);
    TensorBuffer outputEmbeddings = TensorBuffer.createFixedSize(<int>[1, 1024], TfLiteType.float32);

    _interpreter.runForMultipleInputs(
      [input],
      {0: outputScores.buffer, 1: outputEmbeddings.buffer},
    );

    return [outputScores, outputEmbeddings];
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

    void _processWavFile() async {
    // Substitua pelo caminho do arquivo WAV no seu dispositivo
    String wavFilePath = 'path/to/your/wav/file.wav';

    Float32List inputData = await loadWavFile(wavFilePath);
    List<dynamic> inferenceResult = runInference(inputData);
    setState(() {
      _result = 'Inference result: ${inferenceResult.toString()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$_result',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _processWavFile,
                child: Text('Process WAV File'),
              ),
            ],
          ),
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
