#!/usr/bin/env python
import rospy
from switchbot_ros.srv import Command
from switchbot_ros.srv import CommandResponse
from switchbot import SwitchBotRequest

class SwitchBotServer:
    """
    Control your switchbot with IFTTT.
    Please setup your SwitchBot device as the README shows.
    """
    def __init__(self):
        self._ifttt_key = rospy.get_param('~ifttt_key')
        self.nickname = rospy.get_param('~nickname', None)
        self.command_server = rospy.Service('~command', Command, self.command)

    def _post_command(self, command):
        event = self.nickname + command
        key = self._ifttt_key
        switchbot_request = SwitchBotRequest(event='', )
        
    def _post_command_and_wait(self, command, timeout):
        
    def command(self, req):
        return CommandResponse(
            *self._
        )
        

if __name__ == '__main__':
    rospy.init_node('switchbot_server')
    app = SwitchBotServer()
    rospy.spin()
    
