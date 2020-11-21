#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(unless (boundp '*elevator-action*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/elevator-action.l"))
(unless (boundp '*utils*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l"))

(setq *go-to-2f-hall* t)

(ros::load-ros-manifest "geometry_msgs")
(ros::advertise "/initialpose" geometry_msgs::PoseWithCovarianceStamped 1)

;; global variable
(setq *2f-elevator-hall-2* (make-coords :pos #f(2145 -27902 0.000) :rpy (float-vector 0 0 0)))

(unless (boundp '*ri*) (fetch-init))

(defun go-to-2f-hall()
  (ros::ros-info "function go-to-2f-hall")
  (go-to-current-floor-elevator-hall)
  (get-on-and-off-eng2-elevator (get-current-floor) 2)
  (send *ri* :move-to *2f-elevator-hall-2* :frame-id "/map")
  )
