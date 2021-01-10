#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(unless (boundp '*define-mission*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/define-mission.l"))
(unless (boundp '*go-to-office*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-office.l"))
(unless (boundp '*go-to-2f-hall*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-2f-hall.l"))
(unless (boundp '*pass-mission-from-fetch-to-spot*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/pass-mission-from-fetch-to-spot.l"))
(unless (boundp '*get-lunch-box*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/get-lunch-box.l"))
(unless (boundp '*go-to-73b2*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-73b2.l"))

(setq *demo* t)

(defun kitchen-car-mission()
  (go-to-2f-hall)
  (pass-mission-from-fetch-to-spot)
  (get-lunch-box))



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
             (go-to-office)
             (kitchen-car-mission)
             (go-to-73b2))
            ((member :kitchen missions)
             (send *ri* :speak-jp "ご飯を買ってきます" :wait t) 
             (kitchen-car-mission)
             (go-to-73b2))
            ((member :office missions)
             (send *ri* :speak-jp "事務室に行ってきます" :wait t)
             (go-to-office)
             (go-to-73b2))
            (t
             nil)) ;; do nothing
      ;; (send *ri* :speak-jp "ドックに戻ります" :wait t)
      ;; (auto-dock)
      (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "xy_goal_tolerance" :double default-xy-tolerance)
      (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "yaw_goal_tolerance" :double default-yaw-tolerance))))

