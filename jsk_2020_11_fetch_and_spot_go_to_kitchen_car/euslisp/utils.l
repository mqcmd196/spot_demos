#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(setq *utils* t)

;; for get-current-floor function
(ros::load-ros-manifest "std_msgs")

;; for switchbot ros
(ros::roseus "switchbot_publisher")
(ros::load-ros-manifest "switchbot_ros")
(ros::wait-for-service "switchbot_server/on")
(ros::wait-for-service "switchbot_server/off")
(ros::wait-for-service "switchbot_server/press")
(ros::advertise "/switchbot_server/command" switchbot_ros::CommandTopic 1)

;; global variables 
(setq *default-local-inflation-radius* (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
(setq *default-global-inflation-radius* (ros::get-param "/move_base/global_costmap/inflater/inflation_radius"))
(setq *default-max-vel-x* (ros::get-param "/move_base/TrajectoryPlannerROS/max_vel_x"))
(setq *default-min-vel-x* (ros::get-param "/move_base/TrajectoryPlannerROS/min_vel_x"))
(setq *default-clearing-rotation* (ros::get-param "/move_base/clearing_rotation_allowed"))

(defun get-current-floor()
  (let (msg floor)
	(setq msg (one-shot-subscribe "/map_tf_mux/selected" std_msgs::String))
	(setq floor (string-right-trim "f_tf" (subseq (send msg :data) 6)))
	(read-from-string floor)))

(defun change-dynamic-param(&key 
			    (local-inflation-radius *default-local-inflation-radius*) 
			    (global-inflation-radius *default-global-inflation-radius*) 
			    (max-vel-x *default-max-vel-x*) 
			    (min-vel-x *default-min-vel-x*) 
			    (clearing-rotation *default-clearing-rotation*))
  (ros::ros-info "Parameters have been changed. local_inflation_radius:~d global_inflation_radius:~d max_vel_x:~d min_vel_x:~d" local-inflation-radius global-inflation-radius max-vel-x min-vel-x)
  (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
  (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius)
  (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "max_vel_x" :double max-vel-x)
  (ros::set-dynamic-reconfigure-param "/move_base/TrajectoryPlannerROS" "min_vel_x" :double min-vel-x)
  (ros::set-dynamic-reconfigure-param "/move_base" "clearing_rotation_allowed" :bool nil)
  (unix:sleep 1)
  (send *ri* :clear-costmap))

(defun call-service (service req)
  ;; cited from elevator_move_base_pr2
  (if (ros::wait-for-service service 0)
      (ros::service-call service req)
      nil))

(defun switchbot-srv (nickname command)
  (let
      ((req (instance switchbot_ros::CommandRequest :init))
       res)
    (send req :nickname nickname)
    (setq res (ros::service-call (concatenate string "switchbot_server/" command) req t))))

(defun switchbot-topic (nickname command &key (times 1) (sleep 1))
  (let
      ((msg (instance switchbot_ros::CommandTopic :init)))
    (send msg :nickname nickname)
    (send msg :command command)
    (send msg :times times)
    (send msg :sleep sleep)
    (ros::publish "/switchbot_server/command" msg)))
