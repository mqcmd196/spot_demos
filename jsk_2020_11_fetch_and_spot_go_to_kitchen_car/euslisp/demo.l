#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/define-mission.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-office.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-2f-hall.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/pass-mission-from-fetch-to-spot.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/get-lunch-box.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/go-to-73b2.l")

(defun kitchen-car-mission()
  (go-to-2f-hall)
  (pass-mission-from-fetch-to-spot)
  (get-lunch-box)
  )

(defun demo()
  (unless (boundp '*ri*) (progn (fetch-init) (ros::ros-info "initializing...")))
  (ros::ros-info "start the fetch and spot demo")
  (define-mission) ;; two mission flags would be changed

  (cond ((and *kitchen-car-mission-flag* *office-mission-flag*)
		 (go-to-office)
		 (kitchen-car-mission)
		 (go-to-73b2))
		((*kitchen-car-mission-flag*)
		 (kitchen-car-mission)
		 (go-to-73b2))
		((*office-mission-flag*)
		 (go-to-office)
		 (go-to-73b2))
		((not (and *kitchen-car-mission-flag* *office-mission-flag*))
		 (send *ri* :speak-jp "ドックに戻ります" :wait t)
		 (auto-dock)))
  )

