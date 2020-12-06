#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "package://jsk_maps/src/change-floor.l")
(load "package://jsk_fetch_startup/euslisp/navigation-utils.l")
(unless (boundp '*elevator-action*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/elevator-action.l"))
(unless (boundp '*utils*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/utils.l"))

(setq *go-to-office* t)

(ros::load-ros-manifest "geometry_msgs")
(ros::advertise "/initialpose" geometry_msgs::PoseWithCovarianceStamped 1)

;; auto-door-coords
(setq *3f-auto-door-1* (make-coords :pos #f(10574 -28000 0) :rpy (float-vector 0 0 0)))
(setq *3f-auto-door-2* (make-coords :pos #f(20473 -32738 0) :rpy (float-vector 0 0 0)))
(setq *3f-auto-door-3* (make-coords :pos #f(22627 -32752 0) :rpy (float-vector pi 0 0)))
(setq *3f-auto-door-4* (make-coords :pos #f(12574 -28000 0) :rpy (float-vector pi 0 0)))

;; define movements
(defun go-to-3f-auto-door(door)
  (send *ri* :clear-costmap)
  (send *ri* :speak-jp (concatenate string (string door) "番目の自動ドアに向かいます") :wait t)  
  (cond ((= door 1)
		 (send *ri* :move-to *3f-auto-door-1* :frame-id "/map"))
		((= door 2)
		 (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3)
		 (send *ri* :move-to *3f-auto-door-2* :frame-id "/map")
		 (change-dynamic-param))
		((= door 3)
		 (send *ri* :move-to *3f-auto-door-3* :frame-id "/map"))
		((= door 4)
		 (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3)
		 (send *ri* :move-to *3f-auto-door-4* :frame-id "/map")
		 (change-dynamic-param)))
  )

(defun shake-head()
  (send *ri* :angle-vector)
  )

(defun go-through-3f-auto-door()
  (send *ri* :speak-jp "一気に進みます" :wait t)
  (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3 :max-vel-x 0.6 :min-vel-x 0.3)
  (send *ri* :go-pos 2.5 0 0)
  (change-dynamic-param)
  )

(defun go-to-office-kyoin()
  (send *ri* :clear-costmap)
  (send *ri* :speak-jp "事務室にむかいます" :wait t)
  (send *ri* :move-to (make-coords :pos #f(51100 -29876 0) :rpy (float-vector 0 0 0)) :frame-id "/map")
  )

(defun go-to-office()
  (unless (boundp '*ri*) (fetch-init))  
  (go-to-current-floor-elevator-hall)
  (get-on-and-off-eng2-elevator (get-current-floor) 3)
  (go-to-3f-auto-door 1)
  ;; shake head
  ;; auto-door switch off
  (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
  (wait-for-julius-trigger "すすんで")
  (go-through-3f-auto-door)
  ;; auto-door switch on
  ;; shake head
  ;; auto-door switch off
  (go-to-3f-auto-door 2)
  (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
  (wait-for-julius-trigger "すすんで")
  (go-through-3f-auto-door)
  ;; auto-door switch on
  (go-to-office-kyoin)
  (send *ri* :speak-jp "届け物をしにきました" :wait t)
  (send *ri* :speak-jp "受け取ったら，受け取りましたと言ってください" :wait t)
  (wait-for-julius-trigger "うけとりました")
  (send *ri* :speak-jp "戻ります" :wait t)
  (go-to-3f-auto-door 3)
  ;; shake head
  ;; auto-door switch off
  (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
  (wait-for-julius-trigger "すすんで")
  (go-through-3f-auto-door)
  ;; switch on
  ;; shake head
  ;; auto-door switch off
  (go-to-3f-auto-door 4)
  (send *ri* :speak-jp "自動ドアがあいたらすすんでと言ってください" :wait t)
  (wait-for-julius-trigger "すすんで")
  (go-through-3f-auto-door)
  ;; auto-door switch on
  )
