#!/usr/bin/env python3
import urllib.request
import time

class SwitchBotRequest:
    """
    For pressing switchbot with IFTTT.
    Please setup your SwitchBot device as the README shows.
    """
    def __init__(self, event, key):
        self.event = event
        self.key = key
        self.url = "https://maker.ifttt.com/trigger/" + self.event + "/with/key/" + self.key
        self.status = None

    def request(self):
        req = urllib.request.Request(self.url)
        with urllib.request.urlopen(req) as res:
            self._body = res
        self.status = self._body.status
        
    def continuous_request(self, times, margin_sec):
       # add the least margin_sec
       for t in range(times):
           self.request()
           time.sleep(margin_sec)
