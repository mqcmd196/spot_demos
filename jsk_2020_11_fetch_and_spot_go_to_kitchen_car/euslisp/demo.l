#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(unless (boundp '*define-mission*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/define-mission.l"))
(unless (boundp '*go-to-office*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-office.l"))
(unless (boundp '*go-to-2f-hall*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-2f-hall.l"))
(unless (boundp '*pass-mission-from-fetch-to-spot*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/pass-mission-from-fetch-to-spot.l"))
(unless (boundp '*get-lunch-box*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/get-lunch-box.l"))
(unless (boundp '*go-to-73b2*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-73b2.l"))

(setq *73b2-door-front* (make-coords :pos #f(1365.036 6617.811 0) :rpy (float-vector pi 0 0)))
(setq *73b2-corridor* (make-coords :pos #f(-774.159 6709.777 0) :rpy (float-vector pi 0 0)))

(setq *demo* t)

(defun get-out-from-73b2()
  (let ((local-inflation-radius (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
        (global-inflation-radius (ros::get-param "/move_base/global_costmap/inflater/inflation_radius")))
    (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double 0.3)
    (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double 0.3)
    (send *ri* :move-to *73b2-door-front* :frame-id "/map")
    (send *ri* :move-to *73b2-corridor* :frame-id "/map")
    (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
    (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius)))
  
(defun kitchen-car-mission()
  (go-to-2f-hall)
  (pass-mission-from-fetch-to-spot)
  (go-to-73b2))

(defun demo()
  (let ((default-xy-tolerance (ros::get-param "/move_base/TrajectoryPlannerROS/xy_goal_tolerance")) 
	(default-yaw-tolerance (ros::get-param "/move_base/TrajectoryPlannerROS/yaw_goal_tolerance")))
    (unless (boundp '*ri*)
      (fetch-init)
      (ros::ros-info "initializing..."))
    (ros::ros-info "start the fetch and spot demo")
    (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "xy_goal_tolerance" :double 0.1)
    (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "yaw_goal_tolerance" :double 0.05)
    (undock)
    (let ((missions (define-mission)))
      (cond ((and (member :kitchen missions) (member :office missions))
             (send *ri* :speak-jp "事務室に行ってからご飯を買ってきます" :wait t)
	     (get-out-from-73b2)
             (go-to-office)
             (kitchen-car-mission)
             (go-to-73b2))
            ((member :kitchen missions)
             (send *ri* :speak-jp "ご飯を買ってきます" :wait t)
             (get-out-from-73b2)
             (kitchen-car-mission)
             (go-to-73b2))
            ((member :office missions)
             (send *ri* :speak-jp "事務室に行ってきます" :wait t)
	     (get-out-from-73b2)
             (go-to-office)
             (go-to-73b2))
            (t
             nil)) ;; do nothing
      ;; (send *ri* :speak-jp "ドックに戻ります" :wait t)
      ;; (auto-dock)
      (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "xy_goal_tolerance" :double default-xy-tolerance)
      (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "yaw_goal_tolerance" :double default-yaw-tolerance))))

