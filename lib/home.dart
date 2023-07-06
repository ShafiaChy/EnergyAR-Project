import 'dart:async';
import 'package:augmented_home_control/dashboard.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tcp_socket_connection/tcp_socket_connection.dart';
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
  bool isConnected = false;
  bool webMode = false;

  // local network
  TcpSocketConnection client = TcpSocketConnection("192.168.4.1", 5000);

  @override
  void initState() {
    initCamera();
    // Timer.periodic(const Duration(seconds: 10), (timer) async {
    //   Map<String, dynamic> params = {'token': apiKey};
    //   params.addAll(myHome.toMapGet());
    //   var url = Uri.https(host, getPath, params);
    //   var response = await http.get(url);
    //   myHome = IoTHome.fromJson(response.body);
    // });
    super.initState();
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    _objectDetector.close();
    super.dispose();
  }

  void onReceive(String msg) {
    if (msg.contains("D=")) {
      msg = msg.replaceFirst("D=", "");
      var data = msg.split(",");
      myHome.acVolt = int.parse(data[0]);
      myHome.freezeAmp = double.parse(data[1]);
      myHome.fanAmp = double.parse(data[2]);
      myHome.lightAmp = double.parse(data[3]);
      print(myHome.toString());
    }
  }

  Future<void> connectESP() async {
    if (client.isConnected()) {
      client.disconnect();
      isConnected = false;
      snackBar("Disconnected.", Colors.blueAccent, Colors.white);
      return;
    }
    snackBar("Connecting...", Colors.blueAccent, Colors.white);
    await client.connect(3000, onReceive);
    Future.delayed(const Duration(seconds: 3), () {
      if (client.isConnected()) {
        isConnected = true;
        snackBar("Connected to ESP.", Colors.blueAccent, Colors.white);
      } else {
        snackBar("Failed to connect!", Colors.redAccent, Colors.white);
      }
    });
  }

  snackBar(String msg, Color bg, Color fg) {
    ScaffoldMessenger.of(context).clearSnackBars();
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
      if (objectName[object.index] != "none") {
        detectedObject = objectName[object.index];
      }
    }
    _isBusy = false;
    if (mounted) setState(() {});
  }

  Widget showUsages() {
    if (detectedObject.contains('off')) return const SizedBox.shrink();
    int volt = myHome.acVolt;
    double amp = 0, load = 0;
    if (detectedObject.contains('freeze')) {
      amp = myHome.freezeAmp;
      load = myHome.freezeWatt();
    } else if (detectedObject.contains('light')) {
      amp = myHome.lightAmp;
      load = myHome.lightWatt();
    } else if (detectedObject.contains('fan')) {
      amp = myHome.fanAmp;
      load = myHome.fanWatt();
    } else {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 50,
      left: 20,
      child: SizedBox(
        width: 150,
        height: 120,
        child: Card(
          color: const Color.fromARGB(132, 255, 255, 255),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Voltage: $volt VAC"),
                Text("Current: ${amp.toStringAsFixed(2)}A"),
                Text("Load: ${load.toInt()} Watt"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void toggleSwitches(String title) {
    if (title == 'Freeze') {
      myHome.freezeState = !myHome.freezeState;
    } else if (title == 'Light') {
      myHome.lightState = !myHome.lightState;
    } else if (title == 'Fan') {
      myHome.fanState = !myHome.fanState;
    }
  }

  Widget showActions() {
    String title = "", cmd = "";
    bool state = false;

    if (detectedObject.contains('freeze')) {
      title = "Freeze";
      state = myHome.freezeState;
      cmd = "R=${state ? 0 : 1}";
    } else if (detectedObject.contains('light')) {
      title = "Light";
      state = myHome.lightState;
      cmd = "L=${state ? 0 : 1}";
    } else if (detectedObject.contains('fan')) {
      title = "Fan";
      state = myHome.fanState;
      cmd = "F=${state ? 0 : 1}";
    } else {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 30,
      left: 20,
      child: SizedBox(
        width: 270,
        height: 70,
        child: Card(
          color: const Color.fromARGB(132, 255, 255, 255),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("$title is ${state ? "ON" : "OFF"}"),
                OutlinedButton(
                  child: Text(
                    state ? "TURN OFF" : "TURN ON",
                    style: const TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    if (webMode) {
                      toggleSwitches(title);
                      try {
                        var url = Uri.parse("${host}state.json");
                        await http.patch(url, body: myHome.toJson());
                      } catch (ex) {
                        toggleSwitches(title);
                      }
                    } else {
                      if (client.isConnected()) {
                        client.sendMessage(cmd);
                        toggleSwitches(title);
                      }
                    }
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
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                detectedObject,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 100,
                            child: ChoiceChip(
                              label: const Text("Web"),
                              selected: webMode,
                              selectedColor: Colors.green,
                              onSelected: (value) => setState(() {
                                webMode = value;
                              }),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 145,
                            child: ChoiceChip(
                              label: const Text("Local"),
                              selected: !webMode,
                              selectedColor: Colors.green,
                              onSelected: (value) => setState(() {
                                webMode = !value;
                              }),
                            ),
                          ),
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
                          if (!webMode)
                            Positioned(
                              right: 10,
                              top: 50,
                              child: FilledButton(
                                style: ButtonStyle(
                                  backgroundColor: isConnected
                                      ? MaterialStateProperty.all(Colors.green)
                                      : MaterialStateProperty.all(Colors.red),
                                ),
                                onPressed: connectESP,
                                child: Icon(isConnected ? Icons.link_off : Icons.link),
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
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const Dashboard()));
                        },
                        child: const Text("Dashboard"),
                      ),
                      // Card(
                      //   elevation: 0,
                      //   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
                      //   color: Colors.purple[50],
                      //   child: Padding(
                      //     padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      //     child: Text(detectedObject),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
