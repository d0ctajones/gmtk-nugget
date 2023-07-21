## Beer
##
## A kickable object that makes a clinking sound when it hits something.
## It's lighter and uses a circular hitbox so it can roll around.

extends "res://objects/interactables/kickable.gd"

class_name Beer

@onready var clink_sound = preload("res://objects/interactables/beer/assets/clink.ogg")

func _init():
    impact_sound = clink_sound
    default_gravity_scale = 0.7
    ignore_gravity_frames_max = 2
