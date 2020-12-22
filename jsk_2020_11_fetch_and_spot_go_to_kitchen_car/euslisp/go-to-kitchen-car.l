#!/usr/env/bin roseus
;; EXPECTED TO USE ON SPOT
;; initialize
(load "package://spoteus/spot-interface.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/speech-recognition-service.l")

(setq *kitchen-car-number* 50)

(spot-init nil)

(defun recognize-marker())

(defun go-to-kitchen-car(kitchen-car-spot-number)
  (send *ri* :navigate-to path kitchen-car-spot-number :initial-localization-fiducial t :initial-localization-waypoint 0))

(defun wait-at-kitchen-car()
  (send *ri* :sit)(unix::sleep 3)
  (send *ri* :stand))

(defun require-lunch()
  (send *ri* :speak-jp "お弁当を買いに来ました．おすすめの弁当を1つください．" :wait t)
  (send *ri* :speak-jp "渡したら，渡しました，と言ってください．" :wait t))

(defun get-lunch()
  (send *ri* :speak-jp "ありがとうございます．今から戻ります"))

(defun go-to-2f-elevator-hall(start-number)
  (send *ri* :navigate-to path -1 :initial-localization-fiducial nil :initial-localization-waypoint start-number))

(defun get-kitchen-car-lunch()
  (recognize-marker)
  (go-to-kitchen-car *kitchen-car-number*)
  (wait-at-kitchen-car)
  (require-lunch)
  (get-lunch)
  (go-to-2f-elevator-hall *kitchen-car-number*)
  (go-to-2f-elevator-hall)
  )
