#!/usr/env/bin roseus
;; EXPECTED TO USE ON SPOT
;; initialize
(load "package://spoteus/spot-interface.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/speech-recognition-service.l")

(setq *get-kitchen-car-lunch* t)

;; Define kitchen car spot number. This is for auto-walk.
(setq *kitchen-car-number* 50)

;; for using AR marker detection
(ros::roseus "go_to_kitchen_car")
(ros::load-ros-manifest "apriltag_ros")


(defun wait-for-detect-apriltag(id)
  (let (res id-res)
    (setq id-res nil)
    (while t
      (setq res (one-shot-subscribe "/tag_detections" apriltag_ros::AprilTagDetectionArray))
      (if (equal (send res :detections) nil)
          (progn
            (ros::ros-info "No AR markers were detected")
            (unix:sleep 1))
        (progn 
          (setq id-res (elt (send (car (send res :detections)) :id) 0))
          (ros::ros-info "AR marker:~d was detected" id-res)))
      (if (equal id-res id)
          (return t)
        (unix:sleep 1)))))

(defun go-to-kitchen-car(kitchen-car-spot-number)
  (ros::ros-info "go to spot no.~d" kitchen-car-spot-number)
  (send *ri* :navigate-to path kitchen-car-spot-number :initial-localization-fiducial t :initial-localization-waypoint 0))

(defun wait-at-kitchen-car()
  (ros::ros-info "wait-at-kitchen-car")
  (send *ri* :sit)(unix::sleep 3))

(defun require-lunch()
  (ros::ros-info "require lunch")
  ;; (send *ri* :speak-jp "お弁当を買いに来ました．おすすめの弁当を1つください．" :wait t)
  ;; (send *ri* :speak-jp "渡したら，渡しました，と言ってください．" :wait t)
  )

(defun get-lunch()
  (ros::ros-info "get lunch")
  ;; (send *ri* :speak-jp "ありがとうございます．今から戻ります"
  )

(defun go-to-2f-elevator-hall(start-number)
  (send *ri* :navigate-to path -1 :initial-localization-fiducial nil :initial-localization-waypoint start-number))

(defun get-kitchen-car-lunch()
  (wait-for-detect-apriltag 202)
  (go-to-kitchen-car *kitchen-car-number*)
  (wait-at-kitchen-car)
  (require-lunch)
  (get-lunch)
  (go-to-2f-elevator-hall *kitchen-car-number*)
  (go-to-2f-elevator-hall)
  )
