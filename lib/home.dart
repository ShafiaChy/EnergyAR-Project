import 'dart:async';
import 'package:augmented_home_control/iot_model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'consts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraDescription camera = cameras[backCam];
  late CameraController _controller;
  late ImageLabeler _objectDetector;
  List<String> objectName = [];
  String detectedObject = "No Object";
  bool _isCameraReady = false;
  bool _isBusy = false;
  double zoomLevel = 1.0;

  @override
  void initState() {
    initCamera();
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      Map<String, dynamic> params = {'token': apiKey};
      params.addAll(myHome.toMapGet());
      var url = Uri.https(host, getPath, params);
      var response = await http.get(url);
      myHome = IoTHome.fromJson(response.body);
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    _objectDetector.close();
    super.dispose();
  }

  snackBar(String msg, Color bg, Color fg) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: fg)), backgroundColor: bg),
    );
  }

  Future<void> initCamera() async {
    // ------------ Local Model
    const modelPath = "flutter_assets/assets/model.tflite";
    final optionsLocal = LocalLabelerOptions(modelPath: modelPath, confidenceThreshold: 0.75);
    var file = await rootBundle.loadString('assets/labels.txt');
    objectName = file.split('\n');
    // ------------ Default model
    final optionsDefault = ImageLabelerOptions(confidenceThreshold: 0.75);
    _objectDetector = ImageLabeler(options: optionsLocal);

    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller.initialize();
    if (_controller.value.isInitialized) {
      _isCameraReady = true;
      _controller.startImageStream((image) {
        final inputImage = convertImage(image);
        processImage(inputImage);
      });
      if (mounted) setState(() {});
    }
  }

  InputImage convertImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation ?? InputImageRotation.rotation0deg,
      inputImageFormat: inputImageFormat ?? InputImageFormat.yuv_420_888,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  Future<void> processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    final objects = await _objectDetector.processImage(inputImage);
    detectedObject = "No Object";
    for (int i = 0; i < objects.length; i++) {
      var object = objects[i];
      detectedObject = objectName[object.index];
    }
    _isBusy = false;
    if (mounted) setState(() {});
  }

  Widget showUsages() {
    if (detectedObject.contains('off')) return const SizedBox.shrink();
    int volt = 0;
    double amp = 0, load = 0;
    if (detectedObject.contains('tube')) {
      volt = myHome.bulbVolt;
      amp = myHome.bulbAmp;
      load = myHome.bulbWatt();
    } else if (detectedObject.contains('light')) {
      volt = myHome.lightVolt;
      amp = myHome.lightAmp;
      load = myHome.lightWatt();
    } else if (detectedObject.contains('fan')) {
      volt = myHome.fanVolt;
      amp = myHome.fanAmp;
      load = myHome.fanWatt();
    }
    return Positioned(
      top: 50,
      left: 20,
      child: SizedBox(
        width: 150,
        height: 120,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Voltage: $volt VAC"),
                Text("Current: ${amp}A"),
                Text("Load: $load Watt"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget showActions() {
    String title = "";
    bool state = false;
    Map<String, dynamic> params = {'token': apiKey};
    if (detectedObject.contains('tube')) {
      title = "Tubelight";
      state = myHome.bulbState;
      params.addEntries(myHome.toMapBulb(!state).entries);
    } else if (detectedObject.contains('light')) {
      title = "Light";
      state = myHome.lightState;
      params.addEntries(myHome.toMapLight(!state).entries);
    } else if (detectedObject.contains('fan')) {
      title = "Fan";
      state = myHome.fanState;
      params.addEntries(myHome.toMapFan(!state).entries);
    }
    return Positioned(
      bottom: 30,
      left: 20,
      child: SizedBox(
        width: 270,
        height: 70,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("$title is ${state ? "ON" : "OFF"}"),
                OutlinedButton(
                  child: Text(state ? "TURN OFF" : "TURN ON"),
                  onPressed: () async {
                    var url = Uri.https(host, updatePath, params);
                    //print(url.toString());
                    await http.get(url);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isCameraReady
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: CameraPreview(
                      _controller,
                      child: Stack(
                        children: [
                          detectedObject == "No Object" ? const SizedBox.shrink() : showUsages(),
                          detectedObject == "No Object" ? const SizedBox.shrink() : showActions(),
                          Positioned(
                            right: 0,
                            bottom: 20,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                min: 1.0,
                                max: 3.0,
                                divisions: 6,
                                value: zoomLevel,
                                onChanged: (value) {
                                  zoomLevel = value;
                                  _controller.setZoomLevel(zoomLevel);
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Center(
                        child: Text(
                          "Augmented IoT Home Control",
                          style: TextStyle(color: Colors.deepPurple, fontSize: 22),
                        ),
                      ),
                      const Text("Move camera around to see actions."),
                      Card(
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
                        color: Colors.purple[50],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Text(detectedObject),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
