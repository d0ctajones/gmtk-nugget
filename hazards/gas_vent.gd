extends StaticBody2D

@export var attack_interval: float = 1.0
@export var attack_duration: float = 1.0


@onready var attack_method = get_node("GasJetLong")

var attack_sound = preload("res://hazards/gas_vent.ogg")

func _ready():
    remove_child(attack_method)
    _create_attack_interval_timer()


func _create_attack_interval_timer():
    var timer = Timer.new()
    timer.name = "attack_interval"
    timer.set_wait_time(attack_interval)
    timer.connect('timeout', Callable(self, 'attack'))

    add_child(timer)
    timer.start()


func attack():
    get_node("attack_interval").stop()
    add_child(attack_method)

    var sound_player = play_sound(attack_sound)
    await get_tree().create_timer(attack_duration).timeout
    sound_player.queue_free()

    remove_child(attack_method)
    get_node("attack_interval").start()

func play_sound(sound):
    var sound_player = AudioStreamPlayer2D.new()
    sound_player.set_stream(sound)
    sound_player.autoplay = true
    sound_player.max_distance = 500.0
    sound_player.position = get_parent().position
    sound_player.connect('finished', Callable(sound_player, 'queue_free'))

    add_child(sound_player)

    return sound_player
