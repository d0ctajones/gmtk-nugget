extends "res://objects/physics_object.gd"
class_name Beer


func _init():
    clink_sound = preload("res://objects/beer/assets/clink.ogg")
    DEFAULT_GRAVITY_SCALE = 0.7
    ignore_gravity_frames_max = 2
