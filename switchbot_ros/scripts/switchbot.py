#!/usr/bin/env python3
import urllib.request
import time

class SwitchBotAction:
    """
    For pressing switchbot with IFTTT.
    Please setup your SwitchBot device as the README shows.
    """
    def __init__(self, event, key):
        self.event = event
        self.key = key
        self.url = "https://maker.ifttt.com/trigger/" + self.event + "/with/key/" + self.key

    def action(self):
        req = urllib.request.Request(self.url)
        with urllib.request.urlopen(req) as res:
            body = res.read()

    def continuous_action(self, times, margin_sec):
       # add the least margin_sec
       for t in range(times):
           self.action()
           time.sleep(margin_sec)
