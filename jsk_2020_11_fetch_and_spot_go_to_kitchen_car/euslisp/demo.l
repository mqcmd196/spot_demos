#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/define-mission.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-office.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-2f-hall.l")
;; (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/pass-mission-from-fetch-to-spot.l")
;; (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/get-lunch-box.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-73b2.l")

(defun demo()
  (ros::ros-info "initializing...")
  (unless (boundp '*ri*) (fetch-init))
  (ros::ros-info "starting fetch and spot demo")
  (define-mission)
  )

