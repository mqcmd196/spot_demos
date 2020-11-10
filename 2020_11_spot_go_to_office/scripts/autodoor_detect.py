import rospy
from sensor_msgs.msg import CompressedImage
from std_msgs.msg import Bool

class AutoDoorDetector:
    def __init__(self):
        rospy.init_node('autodoor_detector', anonymous=True)
        self.sub = rospy.Subscriber('/coaxial_camera/inference/segmentation/compressed')
        self.pub = rospy.Publisher('/tranparent_obstacle_state')

        # initialize state variable
        self.transparent_obstacle = False

    def callback(self, data):
        self.publisher(data)

    def publisher(self, data):
        self.transparent_obstacle_detector(data)
        self.pub.publish(self.transparent_obstacle)

    def transparent_obstacle_detector(self, data):
        self.data.data
