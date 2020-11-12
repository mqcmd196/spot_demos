#!/usr/bin/env python3
# -*- coding:utf-8 -*-

# Author: Tomoyuki Takahata

import os
import numpy as np
import cv2

import rospy
from cv_bridge import CvBridge, CvBridgeError
from sensor_msgs.msg import Image
from ros_basic import RosBasic

from absl import app
from absl import flags

import tensorflow as tf


FLAGS = flags.FLAGS

flags.DEFINE_string('model_dir', '/home/takahata/savedmodel',
    'The directory containing the savedmodels.')

flags.DEFINE_enum('model_name', 'coaxials_ICNet_5_3stream2_half',
    ['coaxials_ICNet_5_3stream2_half',
        'coaxials_ICNet_5_3stream2_half_tftrt',
        'coaxials_ICNet_5_3stream2',
        'coaxials_ICNet_5_3stream2_tftrt',
        'coaxials_ICNet_RGB'],
    'The directory name of the loading savedmodel.')

flags.DEFINE_integer('id', 0,
    'Camera id. "sensor-id" for csi cameras. /dev/videoID for boson. '
    + 'This argument is useless with TIS cameras.')

flags.DEFINE_bool('inf', True, 'Run inference.')


class RosInference(RosBasic):
    def __init__(self,):
        try:
            self.package_name = 'coaxial_3dmap'
            self.node_name = 'ros_inference'
            self.loop_hz = 30
            super(RosInference, self).__init__(self.package_name, self.node_name, self.loop_hz)

            rospy.on_shutdown(self.shutdown_hook)

            self.times = []
            self.durations = []

            ### colour table for OpenCV
            self.label_colours = [(255, 255, 255), (182, 187, 222), (63, 63, 85)
                    # 0 = 背景:白, 1 = 歩道:肌色, 2 = 通路:茶色
                    ,(0, 0, 255), (21, 238, 241), (21, 241, 36)
                    # 3 = ガラス:赤, 4 = 木:黄色, 5 = 自転車:緑
                    ,(207, 241, 21), (241, 124, 21), (241, 21, 83)
                    # 6 = 切り下げ:黄緑, 7 = 歩行者：水色, 8 = 縁石:青
                    ,(229, 52, 240)]
                    # 9 = 車:ピンク

            # constants of 3-B Boson 320 50deg
            self.effective_vis_width = 610  # 647
            self.effective_vis_height = 490  # 518
            self.offset_w = -10
            self.offset_h = -10
            self.vis_width = 720
            self.vis_height = 540

            self.batch_size = 1
            self.num_of_classes = 10

            self.bridge = CvBridge()
            self.vis_flag = False
            self.fir_flag = False

            self.init_publisher()
            self.init_subscriber()

            if 'half' in FLAGS.model_name:
                self.inf_width = 320
                self.inf_height = 256
            else:
                self.inf_width = 640
                self.inf_height = 512

            if FLAGS.inf:
                self.initialize_inference_model()

            self.loop()

        except rospy.ROSInterruptException as e:
            self.logwarn('ROSInterruptException message:{}'.format(e.message))

    def shutdown_hook(self,):
        self.loginfo('shutdown!!')

    def init_publisher(self,):
        self.loginfo('init_publisher')
        self.vis_image_pub = rospy.Publisher("inference/vis_input", Image, queue_size=10)
        self.fir_image_pub = rospy.Publisher("inference/fir_input", Image, queue_size=10)
        self.inf_image_pub = rospy.Publisher("inference/segmentation", Image, queue_size=10)

    def init_subscriber(self,):
        self.loginfo('init_subscriber')
        rospy.Subscriber('vis_image', Image, self.image_callback, callback_args='vis')
        rospy.Subscriber('fir_image', Image, self.image_callback, callback_args='fir')

    def image_callback(self, data, args):
        # self.loginfo('image_callback args {}, type of data {}'.format(args, type(data)))
        cv_image = self.bridge.imgmsg_to_cv2(data, desired_encoding='passthrough')
        if args == 'vis':
            self.vis_image_raw = cv_image
            self.vis_flag = True
        elif args == 'fir':
            self.fir_image_raw = cv_image
            self.fir_flag = True

    def task_in_loop(self,):
        if all([FLAGS.inf, self.vis_flag, self.fir_flag]):
            self.inf_image = self.inference()
            self.pub_image()
        elif all([self.vis_flag, self.fir_flag]):
            self.concatenate_images()
            self.pub_image()
        else:
            self.loginfo('flag.inf {}, vis_flag {}, fir_flag {}'.format(FLAGS.inf, self.vis_flag, self.fir_flag))


    def pub_image(self,):
        self.vis_image_pub.publish(self.bridge.cv2_to_imgmsg(self.vis_image_rect, "bgr8"))
        self.fir_image_pub.publish(self.bridge.cv2_to_imgmsg(self.fir_image_rect, "bgr8"))
        if FLAGS.inf:
            self.inf_image_pub.publish(self.bridge.cv2_to_imgmsg(self.inf_image, "bgr8"))

    def initialize_inference_model(self):
        self.loginfo('Initialize inference model!')

        self.times.append(rospy.Time.now())

        # Using the Winograd non-fused algorithms provides a small performance boost.
        os.environ['TF_ENABLE_WINOGRAD_NONFUSED'] = '1'

        # Restore model from savedmodel
        export_dir = os.path.join(FLAGS.model_dir, FLAGS.model_name)
        self.sess = tf.compat.v1.Session(graph=tf.Graph())
        tf.python.saved_model.loader.load(self.sess, [tf.saved_model.SERVING], export_dir)

        self.image_tensor = self.sess.graph.get_tensor_by_name('image_tensor:0')  # inputs['image']
        self.output_tensor = self.sess.graph.get_tensor_by_name('ExpandDims:0')  # outputs['classes']
        # output_tensor = self.sess.graph.get_tensor_by_name('softmax_tensor:0')  # outputs['probabilities']

        # Load color table to convert prediction results to images.
        self.color_table = np.array(self.label_colours).astype(np.uint8)
        self.times.append(rospy.Time.now())

    def concatenate_images(self):
        ### TIS DFM37UX265-ML
        # vis_image_rect = cv2.resize(self.vis_image_raw[384-261:384+261, 512-348:512+348], (_WIDTH, _HEIGHT))
        ### TIS DFM37UX273-ML
        vis_w_min = int((self.vis_width  - self.effective_vis_width)/2  + self.offset_w)
        vis_w_max = int((self.vis_width  + self.effective_vis_width)/2  + self.offset_w)
        vis_h_min = int((self.vis_height - self.effective_vis_height)/2 + self.offset_h)
        vis_h_max = int((self.vis_height + self.effective_vis_height)/2 + self.offset_h)
        vis_image_rect = cv2.resize(
            self.vis_image_raw[vis_h_min:vis_h_max, vis_w_min:vis_w_max],
            (self.inf_width, self.inf_height))

        vis = vis_image_rect.reshape(
            (self.batch_size, self.inf_height, self.inf_width, 3)).astype(np.uint8)

        # vis_image_rect = cv2.resize(self.vis_image_raw, (self.inf_width, self.inf_height))
        # vis = vis_image_rect.reshape(
        #     (self.batch_size, self.inf_height, self.inf_width, 3)).astype(np.uint8)

        fir_image_rect = cv2.resize(self.fir_image_raw, (self.inf_width, self.inf_height))
        # fir_image_rect = cv2.flip(fir_image_rect, 1)

        # If "ir" is color
        ir = fir_image_rect[:,:,1].reshape(
            (self.batch_size, self.inf_height, self.inf_width, 1)).astype(np.uint8)

        vis_ir_image_rect = np.concatenate([vis, ir], 3)

        self.vis_image_rect = vis_image_rect
        self.fir_image_rect = fir_image_rect

        return vis_ir_image_rect

    def inference(self):
        # self.loginfo('start inference')
        time_flag = False

        # Concatenate images
        image = self.concatenate_images()
        if time_flag:
            self.times.append(rospy.Time.now())

        # decoderの最終出力値[batch,h,w,num_class]
        predictions = self.sess.run(
            self.output_tensor,
            feed_dict={self.image_tensor: image})

        if time_flag:
            self.times.append(rospy.Time.now())

        # 評価値の最大次元だけとりだす。[h,w,num_class]
        # When output_tensor is 'softmax_tensor:0'
        # pred_classes = np.argmax(np.reshape(
        #     predictions, (self.inf_height, self.inf_width, self.num_of_classes)), axis=2)

        # When output_tensor is 'ExpandDims:0'
        pred_classes = np.reshape(predictions, (self.inf_height, self.inf_width))

        # 予測画像生成：色付けセグメンテーション画像に変換
        pred_decoded_labels = self.color_table[pred_classes]
        inference_image = pred_decoded_labels
        if time_flag:
            self.times.append(rospy.Time.now())

        return inference_image

    def print_durations(self):
        for i in range(len(self.times) - 1):
            duration = self.times[i + 1] - self.times[i]
            self.durations.append(
                duration.seconds * 1000000 + duration.microseconds)
        self.loginfo("Durations: {} us".format(self.durations))


def main(argv):
    del argv
    ros = RosInference()


if __name__ == '__main__':
    app.run(main)
