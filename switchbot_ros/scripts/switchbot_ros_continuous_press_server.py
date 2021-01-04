#!/usr/bin/env python3
import time

import rospy
from switchbot_ros.srv import Command
from switchbot_ros.srv import CommandResponse
from switchbot_ros.msg import CommandTopic

class SwitchBotContinuousServer:

    def __init__(self):
        rospy.init_node('switchbot_ros_continuous_press_server')
        self.continuous_press_start_server = rospy.Service('~start', Command, self.start)
        self.continuous_press_stop_server = rospy.Service('~stop', Command, self.stop)
        self.pub = rospy.Publisher('/switchbot_server/command', CommandTopic, queue_size=1)
        self.flags = {}

    def start(self, data):
        self.flags[data.nickname] = True

    def stop(self, data):
        self.flags[data.nickname] = False

    def publish(self):
        r = rospy.Rate(0.1)
        for nickname in self.flags:
            if self.flags[nickname]:
                msg = CommandTopic()
                msg.nickname = nickname
                msg.command = 'press'
                self.pub.publish(msg)
        r.sleep()

if __name__ == '__main__' :
    try:
        node = SwitchBotContinuousServer()
        while not rospy.is_shutdown():
            node.publish()
    except rospy.ROSInterruptException:
        pass
