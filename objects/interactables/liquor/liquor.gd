## Liquor
##
## A kickable object that makes a clunk sound when it hits the ground.
## Doesn't roll, and uses a cylindrical collision shape.

extends "res://objects/interactables/kickable.gd"

class_name Liquor

func _init():
    impact_sound = preload("res://objects/interactables/liquor/assets/clunk.ogg")
    ignore_gravity_frames_max = 2
    default_gravity_scale = 1.0
