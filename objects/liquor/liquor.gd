extends RigidBody2D

@export var kickable:bool = false

@export var horizontal_fly_time: float = 0.08

var clink_sound = preload("res://objects/liquor/assets/clunk.ogg")

var DEFAULT_GRAVITY_SCALE = 0.9

func set_kickable(is_kickable):
    kickable = is_kickable

func kick(kick_power):
    set_axis_velocity(Vector2.ZERO)

    apply_central_impulse(kick_power)

    gravity_scale = 0

    var timer = Timer.new()
    timer.name = "gravity_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(horizontal_fly_time)
    timer.connect('timeout', Callable(timer, 'queue_free'))
    timer.connect('timeout', Callable(self, '_respect_gravity'))

    add_child(timer)
    timer.start()

func _respect_gravity():
    gravity_scale = DEFAULT_GRAVITY_SCALE

func play_sound(sound):
    var sound_player = AudioStreamPlayer2D.new()
    sound_player.set_stream(sound)
    sound_player.autoplay = true
    sound_player.max_distance = 200.0
    sound_player.position = position
    sound_player.set_volume_db(-25.0)
    sound_player.connect('finished', Callable(sound_player, 'queue_free'))

    get_parent().add_child(sound_player)

func _on_body_entered(body):
    play_sound(clink_sound)
