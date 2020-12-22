#!/usr/env/bin roseus
;; initialize
(unless (boundp '*ri*)(spot-init nil))
(unless (boundp '*get-kitchen-car-lunch*) (load "package://jsk_2020_11_fetch_and_spot_go_to_kitchen_car/euslisp/get-kitchen-car-lunch")) 
