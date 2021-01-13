#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(unless (boundp '*elevator-action*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/elevator-action.l"))
(unless (boundp '*utils*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l"))

(setq *73b2-corridor-return* (make-coords :pos #f(-774.159 6709.777 0) :rpy (float-vector pi 0 0)))
(setq *73b2-door-front-return* (make-coords :pos #f(1365.036 6617.811 0) :rpy (float-vector pi 0 0)))

(setq *go-to-73b2* t)

(ros::load-ros-manifest "geometry_msgs")
(ros::advertise "/initialpose" geometry_msgs::PoseWithCovarianceStamped 1)

(defun go-to-73b2()
  (unless (boundp '*ri*) (fetch-init))
  (send *ri* :speak-jp "研究室へ戻ります" :wait t)
  (go-to-current-floor-elevator-hall)
  (get-on-and-off-eng2-elevator (get-current-floor) 7)
  ;; auto-dock pos is fetch15 dock now.
  ;; (auto-dock)
    (let ((local-inflation-radius (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
        (global-inflation-radius (ros::get-param "/move_base/global_costmap/inflater/inflation_radius")))
      (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double 0.3)
      (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double 0.3)
      (send *ri* :move-to *73b2-door-front* :frame-id "/map")
      (send *ri* :move-to *73b2-corridor* :frame-id "/map")
      (send *ri* :move-to (make-coords :pos #f(2912.922 7180.515 0) :rpy (float-vector 1.549 0 0) :frame-id "/map"))
      (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
      (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius)
      (send *ri* :speak-jp "おつかいタスクを終了しました" :wait t)))
