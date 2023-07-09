extends RigidBody2D

@export var kickable:bool = false

@export var horiztonal_fly_time: float = 0.1

var DEFAULT_GRAVITY_SCALE = 0.8

func set_kickable(is_kickable):
    kickable = is_kickable

func kick(kick_power):
    set_axis_velocity(Vector2.ZERO)

    apply_central_impulse(kick_power)

    gravity_scale = 0

    var timer = Timer.new()
    timer.name = "gravity_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(horiztonal_fly_time)
    timer.connect('timeout', Callable(timer, 'queue_free'))
    timer.connect('timeout', Callable(self, '_respect_gravity'))

    add_child(timer)
    timer.start()

func _respect_gravity():
    gravity_scale = DEFAULT_GRAVITY_SCALE
