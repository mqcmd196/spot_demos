#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(setq *pass-mission-from-fetch-to-spot* t)

(defun pass-mission-from-fetch-to-spot()
  ;; move to in front of the spot
  ;; pass the box
  ;; initial pose
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(127.923 91.9941 81.1796 5.03645 100.431 -82.3717 122.18 5.8556 -0.175604 29.1547)) 10000) ;; carry the bag position
  (send *ri* :wait-interpolation)
  (send *fetch* :torso :angle-vector #f(338.068))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; torso up
  (send *ri* :wait-interpolation)
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(338.068 18.9461 36.2894 -105.354 64.242 -134.754 50.9668 -4.75715 -0.549489 30.1874)) 10000) ;; move the arm to target coords
  (send *ri* :wait-interpolation)
  (send *fetch* :torso :angle-vector #f(100))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; torso down
  (send *ri* :wait-interpolation)
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.31227 18.9901 36.2894 -105.376 64.1762 -134.842 51.0107 -4.86706 -0.538157 30.1654)) 10000) ;; put the box
  (send *ri* :wait-interpolation)
  (send *ri* :stop-grasp)
  (send *ri* :wait-interpolation)
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.21309 40.8968 68.2157 -103.113 107.33 -134.776 51.0107 30.465 -0.583476 30.1874)) 10000) ;; pull the arm
  (send *ri* :wait-interpolation)
  ;; get back and show AR marker
  ;; (unix:sleep 60)
  ;; detect red box
  ;; (unix:sleep 15)
  ;; get the box
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.21309 40.8968 68.2157 -103.113 107.33 -134.776 51.0107 30.465 -0.583476 30.1874)) 10000) ;; pull the arm pos
  (send *ri* :wait-interpolation)
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.31227 18.9901 36.2894 -105.376 64.1762 -134.842 51.0107 -4.86706 -0.538157 30.1654)) 10000) ;; get the box
  (send *ri* :wait-interpolation)
  (send *ri* :start-grasp)
  (send *ri* :wait-interpolation)
  (send *fetch* :torso :angle-vector #f(100)) 
  (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; up torso
  (send *ri* :wait-interpolation)
  (send *fetch* :torso :angle-vector #f(338.068))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; up torso
  (send *ri* :wait-interpolation)
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(338.068 91.9941 81.1796 5.03645 100.431 -82.3717 122.18 5.8556 -0.175604 29.1547)) 10000) ;; for making carry pose
  (send *ri* :wait-interpolation)
  (send *ri* :angle-vector (send *fetch* :angle-vector #f(127.923 91.9941 81.1796 5.03645 100.431 -82.3717 122.18 5.8556 -0.175604 29.1547)) 10000) ;; carry pose
  (send *ri* :wait-interpolation)
  ;; come back to 73b2
  )
