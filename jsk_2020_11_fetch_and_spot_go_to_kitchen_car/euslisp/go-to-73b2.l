#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/elevator-action.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l")

(ros::load-ros-manifest "geometry_msgs")
(ros::advertise "/initialpose" geometry_msgs::PoseWithCovarianceStamped 1)

(defun go-to-73b2()
  (unless (boundp '*ri*) (fetch-init))
  
  (send *ri* :speak-jp "研究室にに戻ります" :wait t)
  (go-to-current-floor-elevator-hall)
  (get-on-and-off-eng2-elevator (get-current-floor) 7)
  (auto-dock)
  )
