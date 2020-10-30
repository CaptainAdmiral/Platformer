import cv2
import numpy as np
import time

STEP_SIZE = 10
MAX_ITER = 255
GUASSIAN_KERNAL_SIZE = 7

filename = input("-> ")

img = cv2.imread(filename,0)
height, width = img.shape
dilatedImg = np.zeros((height, width))


passCount = 0
flag = True
while flag:
    if passCount == MAX_ITER:
        break
    passCount+=1
    print("Pass " + str(passCount))
        
    flag = False
    for i in range(1, width-1):
        for j in range(1, height-1):
            value = img[j,i]
            if img[j+1,i]>value+STEP_SIZE:
                value=img[j+1, i]-STEP_SIZE
                flag = True
            elif img[j-1,i]>value+STEP_SIZE:
                value=img[j-1, i]-STEP_SIZE
                flag = True
            elif img[j,i+1]>value+STEP_SIZE:
                value=img[j, i+1]-STEP_SIZE
                flag = True
            elif img[j,i-1]>value+STEP_SIZE:
                value=img[j, i-1]-STEP_SIZE
                flag = True
            dilatedImg[j,i] = value

    img = dilatedImg.copy()

img = cv2.GaussianBlur(img,(GUASSIAN_KERNAL_SIZE,GUASSIAN_KERNAL_SIZE),0)

cv2.imwrite("SD_"+filename, img)
print("Outputted to SD_"+filename)
