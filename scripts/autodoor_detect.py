import rospy
from sensor_msgs.msg import CompressedImage

class AutoDoorDetector:
    def __init__(self):
        rospy.init_node('autodoor_detector', anonymous=True)
        self.sub = rospy.Subscriber('/')
