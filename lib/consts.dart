import 'package:augmented_home_control/iot_model.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];
const int backCam = 0;
const int frontCam = 1;

String host = "sgp1.blynk.cloud";
String getPath = "/external/api/get";
String updatePath = "/external/api/update";
String apiKey = "siIw3JmatQvW--Nc09vh_iLjYmvZMsXj";

var myHome = IoTHome(
  lightState: false,
  freezeState: false,
  fanState: false,
  acVolt: 0,
  lightAmp: 0,
  freezeAmp: 0,
  fanAmp: 0,
);
