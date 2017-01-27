import cv2
import os.path
import functools
import numpy as np
from matplotlib import pyplot as plt


def variance_of_Laplacian(img):
    """
    takes in a colored image and calculate a score of blurriness
    :param img: colored image
    :return: a numerical score indicatin blurriness
    """
    # gray_img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    return cv2.Laplacian(img, cv2.CV_64F).var()


def comp(item1, item2):
    item1 = item1.split(".")[0]
    item2 = item2.split(".")[0]
    if int(item1) < int(item2):
        return -1
    elif item1[0] == item2[0]:
        return 0
    else:
        return 1


if __name__ == '__main__':
    """
    assumes that the img files are named like "distance_from_home_in_um.ext" e.g. "10000.bmp"
    point the work folder to the folder containing images
    """
    output = []
    output_img = np.zeros((744, 261, 3), dtype=np.uint8)
    list_of_files = os.listdir()
    list_of_files = sorted(list_of_files, key=functools.cmp_to_key(comp))
    for file_name in list_of_files:
        img = cv2.imread(file_name, cv2.IMREAD_GRAYSCALE)
        img = img[440:986, 492:668]
        score = variance_of_Laplacian(img)
        distance = int(file_name.split(".")[0])
        output.append((distance, score))
        # put text on img
        # txt = ["distance from home: {} um".format(file_name.split(".")[0]), str(score)]
        # cv2.putText(img, txt[0], (5, 15), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0,0,255),  1)
        # cv2.putText(img, txt[1], (5, 50), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 255), 1)
        # output_img = np.hstack((output_img, img))
    # output_img = output_img[:, 261:, :]
    # top = output_img[:744//3, :2610//2, :]
    # bottom = output_img[:744//3, 1305:, :]
    # output_img = np.vstack((top, bottom))
    # cv2.imshow("result", output_img)
    # cv2.waitKey(0)
    # cv2.imwrite("result.jpg", output_img)
    plt.scatter([o[0] for o in output], [o[1] for o in output])
    plt.axis([0, 20000, 75, 150])
    plt.xlabel("Distance from home position (um)")
    plt.ylabel("Variance of Laplacian")
    plt.show()
    for (n, s) in output:
        print((n + ": "), s)




