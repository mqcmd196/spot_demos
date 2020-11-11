#!/usr/bin/python3

import rospy
import cv2
from cv_bridge import CvBridge
import numpy as np

from sensor_msgs.msg import Image
from std_msgs.msg import Bool

class AutoDoorDetector:
    def __init__(self):
        rospy.init_node('autodoor_detector', anonymous=True)
        self.sub = rospy.Subscriber('/coaxial_camera/inference/segmentation', Image, self.callback)
        self.pub_bool = rospy.Publisher('/tranparent_obstacle_state', Bool, queue_size=1)
        self.pub_image = rospy.Publisher('/coaxial_camera/inference/segmentation/red_filtered', Image, queue_size=1)

        self.bridge = CvBridge()
        
        # initialize variable
        self.filtered_image = False
        self.transparent_obstacle = False

    def callback(self, data):
        self.filtered_publisher(data)
        # self.bool_publisher(data)

    def filtered_publisher(self, img_message):
        self.filtered_image = self.red_color_pass_filter(img_message)
        self.pub_image.publish(self.filtered_image)
        
    def red_color_pass_filter(self, data):
        # convert to cv2 style
        subscribed_image = data
        cv_image = self.bridge.imgmsg_to_cv2(subscribed_image, "bgr8")
        
        # convert to hsv
        hsv_img = cv2.cvtColor(cv_image, cv2.COLOR_BGR2HSV)
        
        # hsv1
        hsv_min = np.array([0, 243, 50])
        hsv_max = np.array([30, 255, 255])
        mask1 = cv2.inRange(hsv_img, hsv_min, hsv_max)
        
        # hsv 2
        hsv_min = np.array([150, 243, 50])
        hsv_max = np.array([179, 255, 255])
        mask2 = cv2.inRange(hsv_img, hsv_min, hsv_max)
        
        # masking
        masked_hsv_img = mask1 + mask2
        
        # convert to bgr
        masked_img = cv2.cvtColor(masked_hsv_img, cv2.COLOR_HSV2BGR)

        # convert to ros message
        masked_img_message = bridge.cv2_to_imgmsg(masked_img, "bgr8")
        
        return masked_img_message

    # def bool_publisher(self, data):
        # self.transparent_obstacle_detector(data)
        # self.pub.publish(self.transparent_obstacle)

if __name__ == '__main__':
    try:
        node = AutoDoorDetector()
        while not rospy.is_shutdown():
            rospy.sleep(0.1)

    except rospy.ROSInterruptException: pass
