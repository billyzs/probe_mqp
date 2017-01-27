#!/usr/bin/env python

"""
template matching to find the device
adatped from http://docs.opencv.org/3.1.0/d4/dc6/tutorial_py_template_matching.html
"""

import cv2
import numpy as np
from matplotlib import pyplot as plt


"""
observations: TM_CCORR did not generate good results, 'cv2.TM_CCOEFF', 'cv2.TM_CCOEFF_NORMED' generated the best results
"""

if __name__ == '__main__':
    template = cv2.imread("template.png", 0) # grayscale
    w, h = template.shape[::-1]
    img = cv2.imread("whole_device.png")

    # methods = ['cv2.TM_CCOEFF', 'cv2.TM_CCOEFF_NORMED', 'cv2.TM_CCORR',
    #          'cv2.TM_CCORR_NORMED', 'cv2.TM_SQDIFF', 'cv2.TM_SQDIFF_NORMED']
    methods = ['cv2.TM_CCOEFF', 'cv2.TM_CCOEFF_NORMED']
    for m in methods:
        img_local = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        method = eval(m)
        # Apply template Matching
        res = cv2.matchTemplate(img_local, template, method)
        min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)
        # If the method is TM_SQDIFF or TM_SQDIFF_NORMED, take minimum
        if method in [cv2.TM_SQDIFF, cv2.TM_SQDIFF_NORMED]:
            top_left = min_loc
        else:
            top_left = max_loc
        bottom_right = (top_left[0] + w, top_left[1] + h)
        cv2.rectangle(img, top_left, bottom_right, (0,0,0), 2)
        plt.subplot(121), plt.imshow(template, cmap='gray')
        plt.title('template'), plt.xticks([]), plt.yticks([])
        # draw the home position
        center = (top_left[0] + w // 2, top_left[1] + h // 2)
        cv2.circle(img, center, 5, (255, 0, 0), thickness=-1)
        cv2.putText(img, "home position", (center[0], center[1]+20), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0))
        plt.subplot(122), plt.imshow(img)
        plt.title('Detected Point'), plt.xticks([]), plt.yticks([])
        plt.suptitle(m)
        plt.show()
