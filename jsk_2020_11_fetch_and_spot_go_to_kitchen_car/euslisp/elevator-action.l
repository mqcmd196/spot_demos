#!/usr/env/bin roseus
;; load necessary requirements
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(unless (boundp '*speech-recognition-service*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/speech-recognition-service.l"))
(unless (boundp '*utils*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l"))

;; for elevator detect node
(ros::roseus-add-msgs "geometry_msgs")
(ros::roseus-add-msgs "sensor_msgs")
(ros::roseus-add-msgs "roseus")

(setq *elevator-action* t)

;; set global variables
;; (setq *2f-elevator-hall-1* (make-coords :pos #f(2050 -29899 0.000) :rpy (float-vector -pi/2 0 0)))
(setq *2f-elevator-hall-1* (make-coords :pos #f(2078.511 -31178.199 0.000) :rpy (float-vector -pi/2 0 0)))
(setq *2f-elevator-hall-2* (make-coords :pos #f(2145 -27902 0.000) :rpy (float-vector 0 0 0)))
;; (setq *3f-elevator-hall* (make-coords :pos #f(1837 -30734 -0) :rpy (float-vector -pi/2 0 0)))
(setq *3f-elevator-hall* (make-coords :pos #f(2012.483 -30869.959 0) :rpy (float-vector -pi/2 0 0)))
;; (setq *7f-elevator-hall* (make-coords :pos #f(1850 -30746 0) :rpy (float-vector -pi/2 0 0)))
(setq *7f-elevator-hall* (make-coords :pos #f(2088.555 -31225.784 0) :rpy (float-vector -pi/2 0 0)))

;; utils
(defun check-elevator-open (&key (timeout 300))
  ;; This function is cited from jsk_demos/elevator_move_base_pr2
  (let ((topic
         "/check_elevator_open/octree_change_publisher/octree_change_result")
        (change-thre (ros::get-param "change_threshold" 400))
        (change-pc nil) time-start)
    (send *fetch* :head :angle-vector #f(0 0))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 400)
    (send *ri* :wait-interpolation)
    
    (setq time-start (ros::time-now))
    (ros::subscribe
     topic sensor_msgs::PointCloud2
     #'(lambda (msg)
         (when msg
           (let ((stamp (send msg :header :stamp)))
             ;; Wait until point cloud becomes stable
             (when (ros::time> stamp (ros::time+ time-start (ros::time 0.5)))
               (setq change-pc (* (send msg :height) (send msg :width)))
               (ros::ros-info "pointcloud change: ~A, open/closed threshold: ~A"
                              change-pc change-thre))))))

    (ros::rate 10)
    (while (or (null change-pc) (< change-pc change-thre))
      (ros::spin-once)
      (when (ros::time> (ros::time-now)
                        (ros::time+ time-start (ros::time timeout)))
        (ros::warn
         (format nil "Could not detect door opening in ~A [sec]." timeout))
        (send *ri* :speak-jp "ドアが開いていません。")
        (ros::unsubscribe topic)
        (return-from check-elevator-open nil))
      (ros::sleep))

    (ros::unsubscribe topic)
    (ros::ros-info "Door opened.")
    (send *ri* :speak-jp "ドアが開きました。")
    (clear-costmap)
    t))

;; main functions
(defun go-to-current-floor-elevator-hall()
  (let ((current-floor (get-current-floor)))
    (send *ri* :speak-jp (concatenate string (string current-floor) "階のエレベータホールに向かいます") :wait t)
    (ros::ros-info "current floor is ~d" current-floor)
    (cond ((= current-floor 2)
           (send *ri* :move-to *2f-elevator-hall-1* :frame-id "/map")
           (unix:sleep 1))
          ((= current-floor 3)
           (send *ri* :move-to *3f-elevator-hall* :frame-id "/map")
           (unix:sleep 1))
          ((= current-floor 7)
           (send *ri* :move-to *7f-elevator-hall* :frame-id "/map")
           (unix:sleep 1)))))

(defun get-on-and-off-eng2-elevator(start-floor goal-floor)
  ;; Please use this function 2.0m~2.5m before the elevator door.
  (let ((building "/eng2/"))
    ;; speak which button to push
    (ros::ros-info "start floor:~d goal-floor:~d" start-floor goal-floor)
    (cond ((= start-floor goal-floor)
           (send *ri* :speak-jp "入力された階が同じです" :wait t))
          ((> start-floor goal-floor)
           (send *ri* :speak-jp "エレベータの下ボタンを押します" :wait t)
           (switchbot-topic (concatenate string "/eng2/" (string goal-floor) "f/elevator/down/button") "press"))
          ((< start-floor goal-floor)
           (send *ri* :speak-jp "エレベータの上ボタンを押します" :wait t)
           (switchbot-topic (concatenate string "/eng2/" (string goal-floor) "f/elevator/up/button" ) "press")))
    (send *ri* :speak-jp (concatenate string (string goal-floor) "階のボタンを押しました") :wait t)
        
    ;; get on the elevator
    (let ((local-inflation-radius (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
          (global-inflation-radius (ros::get-param "/move_base/global_costmap/inflater/inflation_radius")))
      (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double 0.3)
      (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double 0.3)
      ;; detect door open
      ;; remain pushing current floor button
      (send *ri* :clear-costmap)
      (send *ri* :go-pos 3.0 0 180)
      (unix:sleep 1)
      (send *ri* :speak-jp "エレベータに乗りました" :wait t)
      ;; sw bot request pushing the destination button
      (change-floor (concatenate string "/eng2/" (string goal-floor) "f") :base-frame-name "/base_link")
      (send *ri* :speak-jp (concatenate string "マップを" (string goal-floor) "階に切り替えました") :wait t)
      ;; detect current floor as destination floor
      ;; remain pushing current floor button
      (send *ri* :speak-jp "前に進みます" :wait t)
      (send *ri* :clear-costmap)
      (send *ri* :go-pos 3.5 0 0)
      (unix:sleep 1)
      (send *ri* :speak-jp "エレベータからおりました" :wait t)
      (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
      (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius))))
