extends "res://objects/physics_object.gd"
class_name Liquor


func _init():
    clink_sound = preload("res://objects/liquor/assets/clunk.ogg")
    DEFAULT_GRAVITY_SCALE = 1.0
    ignore_gravity_frames_max = 1
