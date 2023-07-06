import 'package:augmented_home_control/iot_model.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = [];
const int backCam = 0;
const int frontCam = 1;

String host = "https://energyar-50ed5-default-rtdb.firebaseio.com/";

var myHome = IoTHome(
  lightState: false,
  freezeState: false,
  fanState: false,
  acVolt: 0,
  lightAmp: 0,
  freezeAmp: 0,
  fanAmp: 0,
);
