#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

;; for get-current-floor function
(ros::load-ros-manifest "std_msgs")

;; global variables 
(setq *default-local-inflation-radius* (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
(setq *default-global-inflation-radius* (ros::get-param "/move_base/global_costmap/inflater/inflation_radius"))
(setq *default-max-vel-x* (ros::get-param "/move_base/TrajectoryPlannerROS/max_vel_x"))
(setq *default-min-vel-x* (ros::get-param "/move_base/TrajectoryPlannerROS/min_vel_x"))
(setq *default-clearing-rotation* (ros::get-param "/move_base/clearing_rotation_allowed"))

(defun get-current-floor()
  (let (msg floor)
	(ros::advertise "/map_tf_mux/selected" std_msgs::String 1)
	(setq msg (one-shot-subscribe "/map_tf_mux/selected" std_msgs::String))
	(setq floor (string-right-trim "f_tf" (string-left-trim "/eng2/" (send msg :data))))
	(read-from-string floor)
	)
  )

(defun change-dynamic-param(&key (local-inflation-radius *default-local-inflation-radius*) (global-inflation-radius *default-global-inflation-radius*) (max-vel-x *default-max-vel-x*) (min-vel-x *default-min-vel-x*) (clearing-rotation *default-clearing-rotation*))
  (ros::ros-info "Parameters have been changed. local_inflation_radius:~d global_inflation_radius:~d max_vel_x:~d min_vel_x:~d" local-inflation-radius global-inflation-radius max-vel-x min-vel-x)
  (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
  (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius)
  (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "max_vel_x" :double max-vel-x)
  (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "min_vel_x" :double min-vel-x)
  (ros::set-dynamic-reconfigure-param "/move_base/clearing_rotation_allowed" :bool nil)
  (unix:sleep 1)
  (send *ri* :clear-costmap)
  )
