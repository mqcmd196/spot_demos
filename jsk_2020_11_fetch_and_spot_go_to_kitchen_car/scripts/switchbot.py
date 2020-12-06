#!/usr/bin/python3

import urllib.request

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
