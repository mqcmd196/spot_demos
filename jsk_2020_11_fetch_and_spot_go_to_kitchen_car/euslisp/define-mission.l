#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(load "speech-recognition-service.l")

(defun define-mission()
  (let (google-strings missions)
    (send *ri* :speak-jp "要件を教えてください" :wait t)
    (setq google-strings (listen-with-google))
    (when (substringp "ご飯" google-strings)
      (setq missions (append missions (list :kitchen)))
      (ros::ros-info "kitchen car mission flag activated!"))
    (when (substringp "事務室" google-strings)
      (setq missions (append missions (list :office)))
      (ros::ros-info "office mission flag activated!"))
    missions)
  )

