#!/usr/env/bin roseus
;; load necessary requirements
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(load "speech-recognition-service.l")

;; passthrough service
(ros::roseus "passthrough")
(ros::wait-for-service "/passthrough/request")
(ros::wait-for-service "/passthrough/stop")
(setq *pass-req* (instance std_srvs::EmptyRequest :init))

(defun get-on-and-off-eng2-elevator(start-floor goal-floor)
  ;; Please use this function 2.0m before the elevator door.
  (let ((building "/eng2/"))
	
	;; get on the elevator
	(send *ri* :speak-jp "前に進みます" :wait t)
	(send *ri* :clear-costmap)
	(send *ri* :go-pos 3.0 0 180)
	(unix:sleep 1)
	(send *ri* :speak-jp "エレベータに乗りました" :wait t)

	;; request pushing the button
	(send *ri* :speak-jp (concatenate string "エレベータの" (string goal-floor) "階のボタンを押してください") :wait t)
	(change-floor (concatenate string "/eng2/" (string goal-floor) "f") :base-frame-name "/base_link")
	(send *ri* :speak-jp (concatenate string "マップを" (string goal-floor) "階に切り替えました") :wait t)
	(send *ri* :speak-jp "エレベータがついたら進んでと言ってください" :wait t)
	(ros::service-call "/passthrough/request" *pass-req* t)
	(wait-for-julius-trigger "すすんで")

	;; get off the elevator
	(send *ri* :speak-jp "前に進みます" :wait t)
	(ros::service-call "/passthrough/stop" *pass-req* t)
	(send *ri* :clear-costmap)
	(send *ri* :go-pos 3.5 0 0)
	(unix:sleep 1)
	(send *ri* :speak-jp "エレベータからおりました" :wait t)
  )
  )
