extends StaticBody2D

@export var attack_frequency: float = 1.0
@export var attack_duration: float = 1.0


@onready var attack_method = get_node("GasJetLong")
@onready var activate_attack_timer = get_node("ActivateAttackTimer")

func _ready():
    remove_child(attack_method)

func _on_activate_attack_timer_timeout():
    activate_attack_timer.stop()
    add_child(attack_method)

    await get_tree().create_timer(attack_duration).timeout

    activate_attack_timer.start()
    remove_child(attack_method)
