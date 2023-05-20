import cv2
import time

fileName = "FanOn1"
folderName = "FanOn"
outputPath = "output\\" + folderName + "\\"
  
def FrameCapture(path):
    vidObj = cv2.VideoCapture(path)
    count = 1
    success = 1
    prevTime = 0.0
    while success:
        success, image = vidObj.read()
        if not success: return
        if time.time() - prevTime > 0.1:
            cv2.imwrite(outputPath + "%s%d.jpg" % (fileName, count), image)
            print("frame%d" % count)
            prevTime = time.time()
            count += 1
  
if __name__ == '__main__':
    FrameCapture("%s.mp4" % fileName)