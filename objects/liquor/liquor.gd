extends RigidBody2D

@export var kickable:bool = false
@export var ignore_gravity_frames_max:int = 1

var clink_sound = preload("res://objects/liquor/assets/clunk.ogg")

var DEFAULT_GRAVITY_SCALE = 1.0
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

func play_sound(sound):
    var sound_player = AudioStreamPlayer2D.new()
    sound_player.set_stream(sound)
    sound_player.autoplay = true
    sound_player.max_distance = 200.0
    sound_player.position = position
    sound_player.connect('finished', Callable(sound_player, 'queue_free'))

    get_parent().add_child(sound_player)

func _on_body_entered(_body):
    play_sound(clink_sound)
