extends RigidBody2D

@export var kickable:bool = false
@export var ignore_gravity_frames_max:int = 2

@onready var animation_player = $AnimationPlayer

var DEFAULT_GRAVITY_SCALE = 1.5
var ignore_gravity_frame_counter = 0


func _physics_process(_delta):
    if ignore_gravity_frame_counter == ignore_gravity_frames_max:
        _respect_gravity()
    elif ignore_gravity_frame_counter > 0:
        ignore_gravity_frame_counter += 1

func set_kickable(is_kickable):
    kickable = is_kickable

func kick(kick_power):
    ignore_gravity_frame_counter += 1

    set_axis_velocity(Vector2.ZERO)
    apply_central_impulse(kick_power)
    gravity_scale = 0

func _respect_gravity():
    ignore_gravity_frame_counter = 0
    gravity_scale = DEFAULT_GRAVITY_SCALE

func fade_away():
    animation_player.play("fade_away")
