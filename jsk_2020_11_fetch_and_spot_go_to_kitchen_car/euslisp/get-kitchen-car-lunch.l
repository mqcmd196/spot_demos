#!/usr/env/bin roseus
;; EXPECTED TO USE ON SPOT
;; initialize
(load "package://spoteus/spot-interface.l")
(load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/speech-recognition-service.l")
(unless (boundp '*ri*) (spot-init))

(setq *get-kitchen-car-lunch* t)

;; Define kitchen car spot number. This is for auto-walk.
(setq *filepath* "/home/obinata/spot_ws/src/spot_demos/jsk_2020_11_fetch_and_spot_go_to_kitchen_car/autowalk/2021-01-15 kitchencar3.walk")
(setq *kitchen-car-number* 50)

;; for using AR marker detection
(ros::roseus "go_to_kitchen_car")
(ros::load-ros-manifest "apriltag_ros")

;; for using aques_talk
(ros::load-ros-manifest "sound_play")
(ros::advertise "/robotsound_jp" sound_play::SoundRequest)

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
          (ros::ros-info "AR marker:~d was detected" id-res)
          (speak-jp "マーカーを発見しました。動き始めます。")))
      (if (equal id-res id)
          (return t)
        (unix:sleep 1)))))

(defun speak-jp (sentence)
  (let
      ((msg (instance sound_play::SoundRequest :init)))
    (send msg :sound -3)
    (send msg :command 1)
    (send msg :volume 10.0)
    (send msg :arg sentence)
    (ros::publish "/robotsound_jp" msg)))

(defun go-to-kitchen-car(kitchen-car-spot-number)
  (ros::ros-info "go to spot no.~d" kitchen-car-spot-number)
  (send *ri* :navigate-to *filepath* kitchen-car-spot-number :initial-localization-fiducial t :initial-localization-waypoint 0))

(defun wait-at-kitchen-car()
  (ros::ros-info "wait-at-kitchen-car")
  (send *ri* :sit)
  (unix::sleep 3))

(defun require-lunch()
  (ros::ros-info "require lunch")
  (speak-jp "お弁当を買いに来ました．おすすめの弁当をひとつください．")
  (unix::sleep 6)
  (speak-jp "渡したら，渡しました，と言ってください．")
  (unix::sleep 5))

(defun get-lunch()
  (ros::ros-info "get lunch")
  (speak-jp "ありがとうございます．今から戻ります"))

(defun go-to-2f-elevator-hall(start-number)
  (send *ri* :navigate-to *filepath* -1 :initial-localization-fiducial t :initial-localization-waypoint start-number)
  (send *ri* :sit))

(defun get-kitchen-car-lunch()
  (wait-for-detect-apriltag 0)
  (go-to-kitchen-car 87)
  (wait-at-kitchen-car)
  (require-lunch)
  (wait-for-julius-trigger "わたしました")
  (get-lunch)
  (go-to-2f-elevator-hall 87))
