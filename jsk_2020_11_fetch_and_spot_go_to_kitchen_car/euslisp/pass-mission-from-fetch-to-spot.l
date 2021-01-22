#!/usr/env/bin roseus
(require :fetch-interface "package://fetcheus/fetch-interface.l")
(unless (boundp '*fetch*) (fetch-init))
(setq *pass-mission-from-fetch-to-spot* t)

(ros::roseus "boundingboxarray_subscriber")
(ros::load-ros-manifest "jsk_recognition_msgs")

;; (setq *show-marker-position* (make-coords :pos #f(2084.663 -29291.919 0) :rpy (float-vector -pi/2 0 0)))
(setq *show-marker-position* (make-coords :pos #f(2481.15 -28635.8 0) :rpy (float-vector -pi/2 0 0)))
(setq *get-box-position* (make-coords :pos #f(2285.944 -28014.204 0) :rpy (float-vector pi/2 0 0)))

(defun bounding-box-array-cb (msg)
  (ros::ros-info "cb called")
  (setq *bounding-box-list* (send msg :boxes)) ;; boxesは、BoundingBoxのArray(Euslispではlist)
  ;;(ros::ros-info "set box-list")
  (when *bounding-box-list*
    (let* ((b (elt *bounding-box-list* 0))
           (base->obj-coords (ros::tf-pose->coords (send b :pose)))
           (time-stamp (ros::time 0)))
      (when (ros::time> time-stamp (send msg :header :stamp)) ;;rostime揃え
        (return-from bounding-box-array-cb nil))
      (setq *obj-pos* (scale 0.001 (send base->obj-coords :worldpos)))
      (setq *found-obj* t)
      *obj-pos*)))

;; defun pass-box

(defun wait-for-spot-arrived()
  (send *fetch* :move-to (make-coords) :world) ;;reset pos for solving ik
  (send *ri* :angle-vector (send *fetch* :reset-pose) 4000)
  (send *ri* :wait-interpolation)
  (send *fetch* :head :angle-vector #f(0 40))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (setq *found-obj* nil)
  (ros::subscribe "/head_camera_remote/depth_registered/boxes" jsk_recognition_msgs::BoundingBoxArray #'bounding-box-array-cb 1)
  (while (not *found-obj*)
    (ros::spin-once))
  (send *ri* :speak-jp "到着を確認しました" :wait t)
  (unix:sleep 20))

(defun get-box()
  (setq *found-obj* nil)
  ;; (objects (list *fetch* *box-handle-cds*))
  (send *ri* :angle-vector (send *fetch* :reset-pose) 4000)
  (send *ri* :wait-interpolation)
  (send *fetch* :head :angle-vector #f(0 40))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 1000)
  (send *ri* :wait-interpolation)
  (ros::subscribe "/head_camera_remote/depth_registered/boxes" jsk_recognition_msgs::BoundingBoxArray #'bounding-box-array-cb 1)
  (while (not *found-obj*)
    (ros::spin-once))
  (when *found-obj*
    (send *ri* :speak-jp "かごが見つかりました" :wait t)
    (setq *box-handle-cds* (make-coords :pos (scale 1000 *obj-pos*)))
    ;; (send *box-handle-cds* :move-to (make-coords :pos #f(0 0 50)))
    (send *box-handle-cds* :move-to (make-coords :pos #f(0 0 0) :rpy (float-vector 0 0 pi/2))) ;; rotate handle for grasping the box horizontally. translate?? move-to??
    (setq *box-handle-cds-front* (send *box-handle-cds* :copy-worldcoords))
    (send *box-handle-cds-front* :move-to (make-coords :pos #f(-300 0 0)))
    (send *box-handle-cds-front* :move-to (make-coords :pos #f(0 150 0) :rpy (float-vector 0 0 0)))
    (setq *box-handle-cds-front-up* (send *box-handle-cds* :copy-worldcoords))
    ;; (send *box-handle-cds-front-up* :move-to (make-coords :pos #f(-300 0 )))
    (ros::ros-info (format nil "The box's handle: ~A" *box-handle-cds*))
    (send *ri* :speak-jp "腕が動きます．注意してください" :wait t)
    (send *fetch* :torso :angle-vector #f(338.068))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 3000)
    (send *ri* :wait-interpolation)
    (send *ri* :angle-vector (send *fetch* :angle-vector #f(338.068 40.8968 68.2157 -103.113 107.33 -134.776 51.0107 30.465 -0.583476 30.1874)) 10000) ;; prepare for catching.
    (send *ri* :wait-interpolation)
    (send *fetch* :torso :angle-vector #f(100))
    (send *ri* :angle-vector (send *fetch* :angle-vector) 3000) ;; torso down
    (send *ri* :wait-interpolation)
    ;; (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.21309 40.8968 68.2157 -103.113 107.33 -134.776 51.0107 30.465 -0.583476 30.1874)) 10000) ;; move the end-coords in front of the handle FIXEDCOORDS
    (send *fetch* :inverse-kinematics *box-handle-cds-front* 
	  :rotation-axis :z) ;; move the end-coords in front of the handle
    (send *ri* :angle-vector (send *fetch* :angle-vector) 10000)
    (send *ri* :wait-interpolation)
    (send *ri* :stop-grasp)
    (send *ri* :wait-interpolation)
    ;; (send *ri* :angle-vector (send *fetch* :angle-vector #f(1.31227 18.9901 36.2894 -105.376 64.1762 -134.842 51.0107 -4.86706 -0.538157 30.1654)) 10000) ;; for catching the box FIXEDCOORDS
    (send *fetch* :inverse-kinematics *box-handle-cds*
	  :rotation-axis :z) ;; for catching the box
    (send *ri* :angle-vector (send *fetch* :angle-vector) 10000)
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
  (send *ri* :move-to *show-marker-position* :frame-id "/map")
  ;; show the AR marker
  (send *fetch* :torso :angle-vector #f(150))
  (send *ri* :angle-vector (send *fetch* :angle-vector) 3000)
  (send *ri* :wait-interpolation)
  (unix:sleep 60)
  (send *ri* :move-to *get-box-position* :frame-id "/map")
  (wait-for-spot-arrived)
  (get-box))
