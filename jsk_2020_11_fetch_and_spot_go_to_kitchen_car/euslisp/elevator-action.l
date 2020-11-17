#!/usr/env/bin roseus
;; load necessary requirements
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/speech-recognition-service.l")

;; passthrough service
(ros::roseus "passthrough")
(ros::wait-for-service "/passthrough/request")
(ros::wait-for-service "/passthrough/stop")
(setq *pass-req* (instance std_srvs::EmptyRequest :init))

;; set global variables
(setq *2f-elevator-hall-1* (make-coords :pos #f(2050 -29899 0.000) :rpy (float-vector -pi/2 0 0)))
(setq *2f-elevator-hall-2* (make-coords :pos #f(2145 -27902 0.000) :rpy (float-vector 0 0 0)))
(setq *3f-elevator-hall* (make-coords :pos #f(1837 -30734 -0) :rpy (float-vector -pi/2 0 0)))
(setq *7f-elevator-hall* (make-coords :pos #f(1850 -30746 0) :rpy (float-vector -pi/2 0 0)))

(defun go-to-current-floor-elevator-hall()
  (let ((current-floor (get-current-floor)))
	(send *ri* :speak-jp (concatenate string (string current-floor) "階のエレベータホールに向かいます") :wait t)
	(print current-floor)
	(cond ((= current-floor 2)
		   (send *ri* :move-to *2f-elevator-hall-1* :frame-id "/map")
		   (unix:sleep 1))
		  ((= current-floor 3)
		   (send *ri* :move-to *3f-elevator-hall* :frame-id "/map")
		   (unix:sleep 1))
		  ((= current-floor 7)
		   (send *ri* :move-to *7f-elevator-hall* :frame-id "/map")
		   (unix:sleep 1))
		  )
	)
  )

(defun get-on-and-off-eng2-elevator(start-floor goal-floor)
  ;; Please use this function 2.0m~2.5m before the elevator door.
  (let ((building "/eng2/"))
	;; speak which button to push
	(cond ((= start-floor goal-floor)
		   (send *ri* :speak-jp "入力された階が同じです" :wait t))
		  ((> start-floor goal-floor)
		   (send *ri* :speak-jp "エレベータの下ボタンを押してください" :wait t))
		  ((< start-floor goal-floor)
		   (send *ri* :speak-jp "エレベータの上ボタンを押してください" :wait t)))
	
	;; before getting on the elevator
	(send *ri* :speak-jp "エレベータがついたらすすんでと言ってください" :wait t)
	(wait-for-julius-trigger "すすんで")
	
	;; get on the elevator
	(send *ri* :speak-jp "前に進みます" :wait t)
        (let ((local-inflation-radius (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
	      (global-inflation-radius (ros::get-param "/move_base/global_costmap/inflater/inflation_radius")))
	  (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double 0.3)
	  (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double 0.3)
	  (send *ri* :clear-costmap)
	  (send *ri* :go-pos 3.0 0 180)
	  (unix:sleep 1)
	  (send *ri* :speak-jp "エレベータに乗りました" :wait t)
	  ;; request pushing the button
	  (send *ri* :speak-jp (concatenate string "エレベータの" (string goal-floor) "階のボタンを押してください") :wait t)
	  (change-floor (concatenate string "/eng2/" (string goal-floor) "f") :base-frame-name "/base_link")
	  (send *ri* :speak-jp (concatenate string "マップを" (string goal-floor) "階に切り替えました") :wait t)
	  (send *ri* :speak-jp "エレベータがついたら進んでと言ってください" :wait t)
	  (wait-for-julius-trigger "すすんで")

	  ;; get off the elevator
	  (send *ri* :speak-jp "前に進みます" :wait t)
	  (ros::service-call "/passthrough/stop" *pass-req* t)
	  (send *ri* :clear-costmap)
	  (send *ri* :go-pos 3.5 0 0)
	  (unix:sleep 1)
	  (send *ri* :speak-jp "エレベータからおりました" :wait t)
	  (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
	  (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius))
  ))
