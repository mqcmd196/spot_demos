#!/usr/env/bin roseus
(unless (boundp '*go-to-office*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-office.l"))

;; inv auto-door-coords
(setq *3f-auto-door-1-inv* (make-coords :pos #f(10574 -28000 0) :rpy (float-vector pi 0 0)))
(setq *3f-auto-door-2-inv* (make-coords :pos #f(20473 -32738 0) :rpy (float-vector pi 0 0)))
(setq *3f-auto-door-3-inv* (make-coords :pos #f(22627 -32752 0) :rpy (float-vector 0 0 0)))
(setq *3f-auto-door-4-inv* (make-coords :pos #f(12574 -28000 0) :rpy (float-vector 0 0 0)))

(defun go-through-3f-auto-door-with-escape-by-voice()
  (send *ri* :speak-jp "一気に進みます" :wait t)
  (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3 :max-vel-x 0.6 :min-vel-x 0.3)
  (unless (send *ri* :go-pos 2.5 0 0)
    (send *ri* :speak-jp "スタックしました。アシストしてください" :wait t)
    (wait-for-julius-trigger ("なおりました"))
    (send *ri* :speak-jp "再開します" :wait t))
  (change-dynamic-param))

(defun go-through-3f-auto-door-with-escape-by-rotate()
  (send *ri* :speak-jp "一気に進みます" :wait t)
  (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3 :max-vel-x 0.6 :min-vel-x 0.3)
  (unless (send *ri* :go-pos 2.5 0 0)
    (let ((current-coords (send *ri* :state :worldcoords)) (current-angle) (current-pos) (target-pos))
	  (setq current-angle (car (send current-coords :rotation-angle)))
	  (setq current-pos (send current-coords :pos))
	  ;; (setq target-pos ) set target pos
      ;; add condition
	  
      (send *ri* :go-velocity 0 0 1.5))
    )
  (change-dynamic-param))
