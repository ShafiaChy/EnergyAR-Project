import cv2

folderName = "fan on"
outputPath = "output\\" + folderName + "\\"
  
def FrameCapture(path):
    vidObj = cv2.VideoCapture(path)
    count = 1
    success = 1
    while success:
        success, image = vidObj.read()
        cv2.imwrite(outputPath + "frame%d.jpg" % count, image)
        print("frame%d" % count)
        count += 1
  
if __name__ == '__main__':
    FrameCapture("%s.mp4" % folderName)