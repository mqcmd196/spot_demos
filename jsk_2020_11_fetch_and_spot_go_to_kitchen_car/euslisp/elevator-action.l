#!/usr/env/bin roseus
;; load necessary requirements
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(unless (boundp '*speech-recognition-service*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/speech-recognition-service.l"))
(unless (boundp '*utils*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l"))
(unless (boundp '*fetch*) (fetch-init))

;; for elevator detect node
;; (load "package://elevator_move_base_fetch/src/find-elevator-button.l")
(load "package://elevator_move_base_fetch/src/ros-callback-manager.l")
(load "package://elevator_move_base_fetch/src/posedetectiondb-client.l")
(load "package://elevator_move_base_fetch/src/utils.l")
(ros::roseus-add-msgs "geometry_msgs")
(ros::roseus-add-msgs "sensor_msgs")
(ros::roseus-add-msgs "roseus")
;; use these var instead of find-elevator-button.l
(setq *scene* (make-scene-by-tf (instance ros::transform-listener :init)))
(setq *clients* (init-posedetectiondb-client
                 (list (send *scene* :object "/elevator_inside_panel")
                       (send *scene* :object "/elevator_call_panel"))))


(setq *elevator-action* t)

;; set global variables
;; (setq *2f-elevator-hall-1* (make-coords :pos #f(2050 -29899 0.000) :rpy (float-vector -pi/2 0 0)))
(setq *2f-elevator-hall-1* (make-coords :pos #f(2078.511 -31178.199 0.000) :rpy (float-vector -pi/2 0 0)))
;; (setq *2f-elevator-hall-1* (make-coords :pos #f(1840 -31178.199 0.000) :rpy (float-vector -pi/2 0 0)))
(setq *2f-elevator-hall-2* (make-coords :pos #f(2145 -27902 0.000) :rpy (float-vector 0 0 0)))
;; (setq *3f-elevator-hall* (make-coords :pos #f(1837 -30734 -0) :rpy (float-vector -pi/2 0 0)))
(setq *3f-elevator-hall* (make-coords :pos #f(2012.483 -30869.959 0) :rpy (float-vector -pi/2 0 0)))
;; (setq *3f-elevator-hall* (make-coords :pos #f(1840 -30869.959 0) :rpy (float-vector -pi/2 0 0)))
;; (setq *7f-elevator-hall* (make-coords :pos #f(1850 -30746 0) :rpy (float-vector -pi/2 0 0)))
(setq *7f-elevator-hall* (make-coords :pos #f(2088.555 -31225.784 0) :rpy (float-vector -pi/2 0 0)))
;; (setq *7f-elevator-hall* (make-coords :pos #f(1840 -31225.784 0) :rpy (float-vector -pi/2 0 0)))
(setq *2f-elevator* (make-coords :pos #f(2165.701 -33936.09 0) :rpy (float-vector pi/2 0 0)))
(setq *3f-elevator* (make-coords :pos #f(2082.125 -33930.505 0) :rpy (float-vector pi/2 0 0)))
(setq *7f-elevator* (make-coords :pos #f(2147.634 -33961.08 0) :rpy (float-vector pi/2 0 0)))

(setq *tfl* (instance ros::transform-listener :init))
;; (setq *scene* (make-scene-by-tf *tfl*)) scene was loaded@utils.l

;; utils
(defun update (&optional (times 10))
  (let (updated-object (count 0) (found 0) (panel-moved nil))
    ;; wait for result
    (ros::rate 10)
    (while (<= (incf count) times)
      (ros::spin-once)
      (update-robot-position)
      (setq updated-object (update-scene-by-tf *scene* *tfl*))
      (when (memq *panel* updated-object)
        (setq panel-moved t)
        (incf found))
      (ros::ros-info
       (format nil "count: ~A, found: ~A, panel position: ~A"
               count found (send *panel* :worldpos)))
      (when (>= found 3)
        (return))
      (ros::sleep))
    panel-moved))

(defun set-view-target (coords camera frame-id)
  (let ((msg (instance geometry_msgs::PointStamped :init))
        (uv (send camera :screen-point (send coords :worldpos))))
    ;; out of view
    (unless (and (<= 0 (elt uv 0) (send camera :width))
                 (<= 0 (elt uv 1) (send camera :height)))
      (ros::ros-warn "screen-point: ~A is out of view (~A, ~A)"
                     uv (send camera :width) (send camera :height))
      (return-from set-view-target nil))
    (send msg :header :stamp (ros::time-now))
    (send msg :header :frame_id frame-id)
    (send msg :point :x (elt uv 0))
    (send msg :point :y (elt uv 1))
    (send msg :point :z 10) ;; radius [px]
    (ros::publish "view_target" msg)
    t))

(defun look-button-state ()
  (let ((panel-name "/elevator_inside_panel") look-target look-av)
    (update-robot-position)
    (setq *panel* (car (send *scene* :find-object panel-name)))
    (setq look-target
          (car (send *scene* :find-object
                     (format nil "~A~A" (check-current-floor *scene* *tfl*)
                             panel-name))))
    (ros::ros-info "Look at panel position: ~A" (send look-target :worldpos))
    (send *fetch* :reset-pose)
    (send *fetch* :head :look-at (send look-target :worldpos))
    (setq look-av (send *fetch* :angle-vector))

    ;; Move only head quickly
    (send *ri* :spin-once)
    (unless (eps-v= (float-vector (elt look-av 8) (elt look-av 9))
                    (float-vector (elt (send *ri* :state :potentio-vector) 8)
                                  (elt (send *ri* :state :potentio-vector) 9))
                    1.0)
      (send *ri* :angle-vector look-av 1000 :head-controller)
      (send *ri* :wait-interpolation))

    ;; Move arms and torso only when it is needed (i.e. skipped inside elevator)
    ;; (if (equal panel-name "/elevator_call_panel")
    ;;   (send *ri* :angle-vector look-av 5000)
    ;;   (send *ri* :wait-interpolation))

    ;; (if (equal panel-name "/elevator_call_panel")
    ;;     (call-service
    ;;      "/head_camera/mono/pass_through_feature_to_call_panel/request"
    ;;      (instance std_srvs::EmptyRequest :init))
    (call-service "/head_camera/mono/pass_through_image_rect/request" (instance std_srvs::EmptyRequest :init))
    (call-service
     "/head_camera/mono/pass_through_feature_to_inside_panel/request"
     (instance std_srvs::EmptyRequest :init))

    ;; Wait until latest image is available.
    (unix:usleep (* 500 1000))

    ;; Update *scene* (especially pose of *panel*) by TF
    (ros::ros-info "Looking for button...")
    (speak-jp "パネルを探しています。")
    (ros::ros-info "Waiting for vision update...")
    (unless (update 10)
      (ros::ros-info "Could not find button.")
      (speak-jp "見つかりませんでした。")
      (return-from look-button-state nil))
    ;; (if (equal panel-name "/elevator_call_panel")
    ;;     (call-service
    ;;      "/head_camera/mono/pass_through_feature_to_call_panel/stop"
    ;;      (instance std_srvs::EmptyRequest :init))
    (speak-jp "パネルが見つかりました。")
    (call-service "/head_camera/mono/pass_through_image_rect/stop" (instance std_srvs::EmptyRequest :init))
    (call-service
     "/head_camera/mono/pass_through_feature_to_inside_panel/stop"
     (instance std_srvs::EmptyRequest :init))
    t))

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

(defun check-target-floor-arrived(target-floor)
  ;; expected to be used in the elevator
  (call-service "/head_camera/mono/pass_through_image_rect/request" (instance std_srvs::EmptyRequest :init))
  (call-service "/head_camera/mono/pass_through_feature_to_inside_panel/request" (instance std_srvs::EmptyRequest :init))
  ;; ;; look at elevator inside panel
  ;; (let ((look-target
  ;;        (or (find-if #'(lambda (x) (string= (send x :name) "/elevator_number"))
  ;;                     (send *panel* :descendants))
  ;;            *panel*)))
  ;;   (send *fetch* :head :look-at (send look-target :worldpos))
  ;;   ;; Move fast but converge to the target angle vector
  ;;   (until (eps-v= (send *fetch* :angle-vector)
  ;;                  (send *ri* :state :potentio-vector)
  ;;                  1.0)
  ;;          (send *ri* :angle-vector (send *fetch* :angle-vector) 500)
  ;;          (send *ri* :wait-interpolation)))
  ;; detect current floor
  (let ((topic
         (instance ros-callback-message
                   :init roseus::StringStamped "/elevator_number/result"))
        (prev-reset-time (ros::time-now))
        (prev-floor nil)
        (cur-floor nil))
    (ros::rate 10)
    (while (ros::ok)
      ;; (update 1)
      (ros::spin-once)
      (when (send topic :msg)
        (setq cur-floor (string-upcase (send topic :msg :data))))
      (unless (equal cur-floor prev-floor)  ;; Elevator moved, so reset time.
        (ros::ros-info (format nil "Current floor: ~A" cur-floor))
        (setq prev-reset-time (ros::time-now))
        (setq prev-floor cur-floor))
      (when (and cur-floor
                 (substringp (concatenate string "/" (string target-floor) "f") cur-floor))
        (send *ri* :speak-jp "到着しました")
        (call-service "/head_camera/mono/pass_through_image_rect/stop" (instance std_srvs::EmptyRequest :init))
        (call-service "/head_camera/mono/pass_through_feature_to_inside_panel/stop" (instance std_srvs::EmptyRequest :init))
        (return-from check-target-floor-arrived t))
      (ros::sleep))))

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
  (let ((building "/eng2/")
        (local-inflation-radius (ros::get-param "/move_base/local_costmap/inflater/inflation_radius"))
        (global-inflation-radius (ros::get-param "/move_base/global_costmap/inflater/inflation_radius"))
        (start-button)
	(goal-button))
    ;; speak which button to push
    (ros::ros-info "start floor:~d goal-floor:~d" start-floor goal-floor)
    (cond ((= start-floor goal-floor)
           (send *ri* :speak-jp "入力された階が同じです" :wait t))
          ((> start-floor goal-floor)
           (send *ri* :speak-jp "エレベータの下ボタンを押します" :wait t)
           (setq start-button (concatenate string "/eng2/" (string start-floor) "f/elevator/down/button"))
           (setq goal-button (concatenate string "/eng2/" (string goal-floor) "f/elevator/up/button"))
           (switchbot-topic start-button "press")
           (send *ri* :speak-jp (concatenate string (string start-floor) "階の下ボタンを押しました")))
          ((< start-floor goal-floor)
           (send *ri* :speak-jp "エレベータの上ボタンを押します" :wait t)
           (setq start-button (concatenate string "/eng2/" (string start-floor) "f/elevator/up/button" ))
           (setq goal-button (concatenate string "/eng2/" (string goal-floor) "f/elevator/down/button"))
           (switchbot-topic start-button "press")
           (send *ri* :speak-jp (concatenate string (string start-floor) "階の上ボタンを押しました"))))
        
    ;; get on the elevator 
    (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double 0.25)
    (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double 0.15)
    (check-elevator-open)
    (send *ri* :speak-jp "ボタンを長押しします")
    (switchbot-topic start-button "press" :times 4 :sleep 5) ;; for remain open
    (send *ri* :speak-jp "前に進みます")
    (send *ri* :clear-costmap)
    (cond ((= start-floor 2)
           ;; (send *ri* :move-to *2f-elevator* :frame-id "/map" :wait t)
	   (send *ri* :go-pos 2.75 0 180))
	  ((= start-floor 3)
           ;; (send *ri* :move-to *3f-elevator* :frame-id "/map" :wait t)
	   (send *ri* :go-pos 2.9 0 180))
          ((= start-floor 7)
           ;; (send *ri* :move-to *7f-elevator* :frame-id "/map" :wait t)
	   (send *ri* :go-pos 3.0 0 180)))
    (send *ri* :speak-jp "エレベータに乗りました" :wait t)
    (send *fetch* :head :angle-vector #f(-90 11)) ;; for looking at the panel
    (send *ri* :angle-vector (send *fetch* :angle-vector) 400)
    (switchbot-topic goal-button "press") ;; press the destination's button
    (send *ri* :speak-jp (concatenate string (string goal-floor) "階のボタンを押しました"))
    (look-button-state)
    (check-target-floor-arrived goal-floor) ;; detect current floor as destination floor
    (send *ri* :speak-jp "到着したので動きます")
    (switchbot-topic goal-button "press" :times 4 :sleep 5) ;; for remain open
    (change-floor (concatenate string "/eng2/" (string goal-floor) "f") :base-frame-name "/base_link") ;; change map
    (send *ri* :speak-jp (concatenate string "マップを" (string goal-floor) "階に切り替えました"))
    (send *ri* :go-pos-unsafe 0 0 90)
    (send *ri* :clear-costmap)
    (send *ri* :go-pos 4.0 0 0)
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータからおりました" :wait t)
    (ros::set-dynamic-reconfigure-param "/move_base/local_costmap/inflater" "inflation_radius" :double local-inflation-radius)
    (ros::set-dynamic-reconfigure-param "/move_base/global_costmap/inflater" "inflation_radius" :double global-inflation-radius)))
