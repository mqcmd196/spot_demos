#!/usr/bin/env python
import time

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
        self.on_server = rospy.Service('~on', Command, self.on)
        self.off_server = rospy.Service('~off', Command, self.off)
        self.press_server = rospy.Service('~press', Command, self.press)

    def _post_command(self, command):
        event = self.nickname[1:].replace('/', '_') + '_' + command
        key = self._ifttt_key
        # send GET method
        switchbot_request = SwitchBotRequest(event=event, key=key)
        switchbot_request.request()
        # check HTTP status
        status = switchbot_request.status
        msg = switchbot_request.msg
        if status == 200:
            successful = True
            rospy.loginfo('Successfully send the GET to IFTTT server. status:{}, msg:{}'.format(switchbot_request.status, switchbot_request.msg)
        else:
            successful = False
            rospy.logerr('IFTTT error! status:{}, msg:{}'.format(switchbot_request.status, switchbot_request.msg))
        return successful, status, msg

    def on(self, req):
        return CommandResponse(
            *self._post_command('on')
        )

    def off(self, req):
        return CommandResponse(
            *self._post_command('off')
        )

    def press(self, req):
        return CommandResponse(
            *self._post_command('press')
        )

if __name__ == '__main__':
    rospy.init_node('switchbot_server')
    app = SwitchBotServer()
    rospy.spin()
    
