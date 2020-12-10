#!/usr/bin/env python3
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
        self.on_server = rospy.Service('~on', Command, self.on)
        self.off_server = rospy.Service('~off', Command, self.off)
        self.press_server = rospy.Service('~press', Command, self.press)
        
    def _post_command(self, data, command):
        # define response
        resp = CommandResponse()
        # send GET method
        event = data.nickname[1:].replace('/', '_') + '_' + command
        key = self._ifttt_key
        switchbot_request = SwitchBotRequest(event=event, key=key)
        switchbot_request.request()
        # check HTTP status
        resp.status = switchbot_request.status
        resp.msg = switchbot_request.msg
        if resp.status == 200:
            resp.successful = True
            rospy.loginfo('Successfully send the GET to IFTTT server. status:{}, msg:{}'.format(switchbot_request.status, switchbot_request.msg))
        else:
            resp.successful = False
            rospy.logerr('IFTTT HTTP error! status:{}, msg:{}'.format(switchbot_request.status, switchbot_request.msg))
        return resp

    def on(self, data):
        return self._post_command(data, 'on')

    def off(self, data):
        return self._post_command(data, 'off')

    def press(self, data):
        return self._post_command(data, 'press')

if __name__ == '__main__':
    rospy.init_node('switchbot_server')
    app = SwitchBotServer()
    rospy.spin()
