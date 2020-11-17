#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
;; for get-current-floor function
(ros::load-ros-manifest "std_msgs")

(defun get-current-floor()
  (let (msg floor)
	(ros::advertise "/map_tf_mux/selected" std_msgs::String 1)
	(setq msg (one-shot-subscribe "/map_tf_mux/selected" std_msgs::String))
	(setq floor (string-right-trim "f_tf" (string-left-trim "/eng2/" (send msg :data))))
	(read-from-string floor)
	)
  )
