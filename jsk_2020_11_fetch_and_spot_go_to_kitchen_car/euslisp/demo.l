(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(load "speech-recognition-service.l")
(ros::load-ros-manifest "geometry_msgs")
(ros::advertise "/initialpose" geometry_msgs::PoseWithCovarianceStamped 1)

;; passthrough service
(ros::roseus "passthrough")
(ros::wait-for-service "/passthrough/request")
(ros::wait-for-service "/passthrough/stop")
(setq *pass-req* (instance std_srvs::EmptyRequest :init))

(fetch-init)

(defun recognize-mission)

(defun go-to-7f-elevator()
    (undock)
    (send *ri* :move-to (make-coords :pos #f(1850 -30746 0) :rpy (float-vector -pi/2 0 0)) :frame-id "/map")
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータの下ボタンを押してください" :wait t)
    )
    
(defun get-on-7f-elevator()
    ;; (push-elevator-button())
    ;; (confirm-opened-door())
    (send *ri* :clear-costmap)
    (send *ri* :go-pos 3.0 0 180)
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータに乗りました" :wait t)
	(send *ri* :speak-jp "エレベータの3階のボタンを押してください" :wait t)
	(ros::service-call "/passthrough/request" *pass-req* t)
    )

(defun get-off-3f-elevator()
    (change-floor "/eng2/3f" :base-frame-name "/base_link")
    (send *ri* :speak-jp "マップを切り替えました" :wait t)
    ;; (recognize-arrive-at-eng2-3f())
    (send *ri* :clear-costmap)
    ;; CHANGE TO MOVE-TO?
	(ros::service-call "/passthrough/stop" *pass-req* t)
    (send *ri* :go-pos 3.5 0 0)
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータからおりました" :wait t)
    )

(defun go-to-auto-door1()
    (send *ri* :clear-costmap)
    (send *ri* :speak-jp "ひとつめの自動ドアにむかいます" :wait t)
    (send *ri* :move-to (make-coords :pos #f(10574 -27843 0) :rpy (float-vector 0 0 0)) :frame-id "/map")
    )

(defun go-to-auto-door2()
    (send *ri* :clear-costmap)
    (send *ri* :speak-jp "ふたつめの自動ドアにむかいます" :wait t)
    (send *ri* :move-to (make-coords :pos #f(20627 -32752 0) :rpy (float-vector 0 0 0)) :frame-id "/map")
    )

(defun go-to-office-kyoin()
    (send *ri* :clear-costmap)
    (send *ri* :speak-jp "事務室にむかいます" :wait t)
    (send *ri* :move-to (make-coords :pos #f(51100 -29876 0) :rpy (float-vector 0 0 0)) :frame-id "/map")
    )

(defun go-to-auto-door3()
    (send *ri* :clear-costmap)
    (send *ri* :speak-jp "みっつめの自動ドアにむかいます" :wait t)
    (send *ri* :move-to (make-coords :pos #f(22627 -32752 0) :rpy (float-vector pi 0 0)) :frame-id "/map")
    )

(defun go-to-auto-door4()
    (send *ri* :clear-costmap)
    (send *ri* :speak-jp "よっつめの自動ドアにむかいます" :wait t)
    (send *ri* :move-to (make-coords :pos #f(12574 -27843 0) :rpy (float-vector pi 0 0)) :frame-id "/map")
    )

(defun go-to-3f-elevator()
    (send *ri* :clear-costmap)
    (send *ri* :move-to (make-coords :pos #f(1837 -30734 -0) :rpy (float-vector -pi/2 0 0)) :frame-id "/map")
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータの上ボタンを押してください" :wait t)
    )

(defun get-on-elevator2()
    (send *ri* :clear-costmap)
    (send *ri* :go-pos 3.0 0 180)
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータに乗りました" :wait t)
	(ros::service-call "/passthrough/request" *pass-req* t)
	(send *ri* :speak-jp "エレベータの7階のボタンを押してください" :wait t)
    )

(defun get-off-elevator2()
    (change-floor "/eng2/7f" :base-frame-name "/base_link")
    (send *ri* :speak-jp "マップを切り替えました" :wait t)
    ;; (recognize-arrive-at-eng2-3f())
	(ros::service-call "/passthrough/stop" *pass-req* t)
    (send *ri* :clear-costmap)
    (send *ri* :go-pos 3.5 0 0)
    (unix:sleep 1)
    (send *ri* :speak-jp "エレベータからおりました" :wait t)
    )

(defun go-to-73b2()
    (send *ri* :clear-costmap)
    (send *ri* :speak-jp "73B2に向かいます" :wait t)
    (auto-dock)
    )

(defun demo()
    (go-to-7f-elevator)
    (send *ri* :speak-jp "エレベータがついたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (get-on-elevator1)
    (send *ri* :speak-jp "エレベータがついたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (get-off-elevator1)
    (go-to-auto-door1)
    (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (go-to-auto-door2)
    (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (go-to-office-kyoin)
    (send *ri* :speak-jp "用事が済んだら教えてください" :wait t)

    (wait-for-julius-trigger "かえるよ")
    (send *ri* :speak-jp "帰ります" :wait t)
    (go-to-auto-door3)
    (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (go-to-auto-door4)
    (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (go-to-3f-elevator)
    (send *ri* :speak-jp "エレベータがついたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (get-on-elevator2)
    (send *ri* :speak-jp "エレベータがついたらすすんでと言ってください" :wait t)
    (wait-for-julius-trigger "すすんで")
    (get-off-elevator2)
    (go-to-73b2)
    )

;; (defun go-to-front-of-auto-door1()
;;     (send *ri* :move-to (make-coords :pos #f(50000 -31276 0) :rpy (float-vector 0 0 0)) :frame-id "/map")
;;     )

;; (defun go-to-front-of-auto-door2())
    


;; jimusitu kyoin
;; (send *ri* :move-to (make-coords :pos #f(50000 -31276 0) :rpy (float-vector 0 0 0)) :frame-id "/map")

;; jimusitu gakusei
;; (send *ri* :move-to (make-coords :pos #f(50000 -26576 0) :rpy (float-vector 0 0 0)) :frame-id "/map")

;; elevator hall
;; (send *ri* :move-to (make-coords :pos #f(1850 -30746 0) :rpy (float-vector -pi/2 0 0)) :frame-id "/map")


;; memo
;; imu
;; julius 10 -> 2
;; no rotation move_base