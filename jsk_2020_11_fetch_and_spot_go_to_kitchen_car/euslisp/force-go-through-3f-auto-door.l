#!/usr/env/bin roseus
(unless (boundp '*go-to-office*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-office-with-escape.l"))

;; auto-door-coords at rails
(setq *3f-auto-door-2-force* (make-coords :pos #f(21822.95 -32752.961 0) :rpy #f(0.116 0 0)))
(setq *3f-auto-door-3-force* (make-coords :pos #f(21825.617 -32760.204 0) :rpy #f(3.04 0 0)))

(defun force-go-through-auto-door (door)
  (send *ri* :speak-jp "無理やり進みます")
  (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3 :max-vel-x 0.6 :min-vel-x 0.3)
  (let (target-world-pos via-world-pos)
    (cond
      ((= door 1)
       (setq target-world-pos *3f-auto-door-4-inv*)
       (setq via-world-pos *3f-auto-door-1-force*))
      ((= door 2)
       (setq target-world-pos *3f-auto-door-3-inv*)
       (setq via-world-pos *3f-auto-door-2-force*))
      ((= door 3)
       (setq target-world-pos *3f-auto-door-2-inv*)
       (setq via-world-pos *3f-auto-door-3-force*))
      ((= door 4)
       (setq target-world-pos *3f-auto-door-1-inv*)
       (setq via-world-pos *3f-auto-door-4-force*)))
    (ros::ros-info "go to via-world-pos")
    (send *ri* :move-to via-world-pos :frame-id "/map" :retry 1)
    (force-escape-by-rotate target-world-pos 0.21 0.5 3)
    )
  )
