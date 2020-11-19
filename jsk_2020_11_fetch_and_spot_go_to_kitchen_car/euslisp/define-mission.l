#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "speech-recognition-service.l")

;; global variables
(setq *kitchen-car-mission-flag* nil)
(setq *office-mission-flag* nil)

(defun define-mission()
  (let (google-strings)
  (send *ri* :speak-jp "要件を教えてください" :wait t)
  (setq google-strings (listen-with-google))
  (if (substringp "ご飯" google-strings)
	  (progn (setq *kitchen-car-mission-flag* t)
			 (ros::ros-info "kitchen car mission flag activated!")))
  (if (substringp "事務室" google-strings)
	  (progn (setq *office-mission-flag* t)
			 (ros::ros-info "office mission flag activated!")))
  )
  )

