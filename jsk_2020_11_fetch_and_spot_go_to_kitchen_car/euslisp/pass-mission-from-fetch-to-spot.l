#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")

(setq *pass-mission-from-fetch-to-spot* t)

(defun bounding-box-array-cb (msg)
  ;;(ros::ros-info "cb called")
  (setq *bounding-box-list* (send msg :boxes)) ;; boxesは、BoundingBoxのArray(Euslispではlist)
  ;;(ros::ros-info "set box-list")
  (when *bounding-box-list*
    (let* ((b (elt *bounding-box-list* 0))
           (base->obj-coords (ros::tf-pose->coords (send b :pose)))
           (base-coords (send (send *fetch* :base_link_lk) :copy-worldcoords))
           (time-stamp (ros::time 0))
           (obj-pos))
      (when (ros::time> time-stamp (send msg :header :stamp)) ;;rostime揃え
        (return-from bounding-box-array-cb nil))
      (ros::ros-info "tf")
      (setq obj-pos (scale 0.001 (send (send base-coords :transform base->obj-coords) :worldpos)))
      (setq found-obj t)
      (print obj-pos)
      obj-pos)))

;; defun pass-box

(defun get-box (obj-pos)
  (let (target-cds (make-coords :pos (scale 1000 obj-pos)))
    (ros::ros-info (format nil "~A" target-cds))
    (objects (list *fetch* target-cds))
    (send *ri* :speak-jp "腕が動きます．注意してください" :wait t)
    (send *fetch* :torso :angle-vector #f(338.068))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    (send *ri* :angle-vector (send *fetch* :angle-vector #f(338.068 40.8968 68.2157 -103.113 107.33 -134.776 51.0107 30.465 -0.583476 30.1874)) 10000) ;; prepare for catching.
    (send *ri* :wait-interpolation)
    (send *fetch* :torso :angle-vector #f(100))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; torso down
    (send *ri* :wait-interpolation)
    (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.21309 40.8968 68.2157 -103.113 107.33 -134.776 51.0107 30.465 -0.583476 30.1874)) 10000) ;; move the end-coords in front of the handle
    (send *ri* :wait-interpolation)
    (send *ri* :stop-grasp)
    (send *ri* :wait-interpolation)
    (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.31227 18.9901 36.2894 -105.376 64.1762 -134.842 51.0107 -4.86706 -0.538157 30.1654)) 10000) ;; for catching the box
    (send *ri* :wait-interpolation)
    (send *ri* :start-grasp) ;; grasping the box
    (send *ri* :wait-interpolation)
    (send *fetch* :torso :angle-vector #f(100))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    (send *fetch* :torso :angle-vector #f(338.068))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; up torso
    (send *ri* :wait-interpolation)
    (send *ri* :angle-vector (send *fetch* :angle-vector #f(338.068 91.9941 81.1796 5.03645 100.431 -82.3717 122.18 5.8556 -0.175604 29.1547)) 10000) ;; carry the bag position. high torso
    (send *ri* :wait-interpolation)
    (send *ri* :angle-vector (send *fetch* :angle-vector #f(127.923 91.9941 81.1796 5.03645 100.431 -82.3717 122.18 5.8556 -0.175604 29.1547)) 10000) ;; carry the bag position
    (send *ri* :wait-interpolation)))

(defun pass-mission-from-fetch-to-spot()
  ;; move to in the showing AR marker spot
  ;; show the AR marker
  (unix:sleep 60)
  ;; detect the bounding box
  (get-box)
  ;; maware migi
  )
