extends StaticBody2D

@export var attack_interval: float = 1.0
@export var attack_duration: float = 1.0


@onready var attack_method = get_node("GasJetLong")

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

    await get_tree().create_timer(attack_duration).timeout

    remove_child(attack_method)
    get_node("attack_interval").start()
