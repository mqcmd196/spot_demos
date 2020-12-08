#!/usr/bin/env python
import rospy
from switchbot_ros.srv import Command
from switchbot_ros.srv import CommandResponse

class SwitchBotServer:
    """
    Control your switchbot with IFTTT.
    """
    def __init__(self):
        self.device_mac_address = 
    

if __name__ == '__main__':
    rospy.init_node('switchbot_server')
    app = SwitchBotServer()
    rospy.spin()
    
