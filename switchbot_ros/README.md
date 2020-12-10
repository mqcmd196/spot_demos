# switchbot_ros

## usage

First, add your webhooks key at `keys/key.txt`.

To run service server,
```bash
rosrun switchbot_ros switchbot_ros_server.py _ifttt_key:=YOUR_IFTTT_KEY
```

To send command to your switchbot,
```bash
rosservice call /switchbot_server/press /eng2/7f/73b2/bot6/button
```