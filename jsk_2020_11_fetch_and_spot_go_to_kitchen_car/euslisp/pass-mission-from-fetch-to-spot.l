#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(setq *pass-mission-from-fetch-to-spot* t)

(defun pass-mission-from-fetch-to-spot()
  ;; move to in front of the spot
  ;; pass the box
  ;; get back and show AR marker
  (unix:sleep 60)
  ;; detect red box
  (unix:sleep 15)
  ;; get the box
  ;; come back to 73b2
  )
