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

(defun go-through-3f-auto-door-with-escape-by-rotate(door delta)
  (send *ri* :speak-jp "一気に進みます" :wait t)
  (change-dynamic-param :local-inflation-radius 0.3 :global-inflation-radius 0.3 :max-vel-x 0.6 :min-vel-x 0.3)
  (unless (send *ri* :go-pos 2.5 0 0)
    (send *ri* :go-velocity 0 0 1.5)
    
    (let
        ((current-coords (send *ri* :state :worldcoords))
         (current-world-roll)
         (current-world-pos)
         (target-world-pos)
         (target-theta-from-map)
         (target-theta-from-me))
      (setq current-world-roll (car (send current-coords :rotation-angle)))
      (setq current-world-pos (send current-coords :pos))
      ;; set target
      ;; For example, if you want to go through No.1 door, the target is door4-inv.
      (cond
        ((= door 1)
         (setq target-world-pos *3f-auto-door-4-inv*)
         (setq target-theta-from-me pi))
        ((= door 2)
         (setq target-world-pos *3f-auto-door-3-inv*)
         (setq target-theta-from-me pi))
        ((= door 3)
         (setq target-world-pos *3f-auto-door-2-inv*)
         (setq target-theta-from-me 0))
        ((= door 4)
         (setq target-world-pos *3f-auto-door-1-inv*)
         (setq target-theta-from-me 0)))
      ;; when you use critical angle 
      ;; (setq target-angle-from-me )
       
      ;; add condition
      (while (> (abs (- current-world-roll target-theta-from-me)) delta)
        (cond
          ((> (- current-world-roll target-theta-from-me) 0)
           (send *ri* :go-velocity 0 0 -1.5)
           (< (- current-world-roll target-theta-from-me) 0)
           (send *ri* :go-velocity 0 0 1.5)))
        (setq current-world-roll (car (send (send *ri* :state :worldcoords) :rotation-angle))))
      (send *ri* :move-to target-pos))))
      
  (change-dynamic-param))))
