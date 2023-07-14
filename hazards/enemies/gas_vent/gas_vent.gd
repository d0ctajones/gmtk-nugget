extends StaticBody2D

@export var attack_interval: float = 1.0
@export var attack_duration: float = 0.5


@onready var attack_method = get_node("AttackMethod")
@onready var attack_animation = get_node("AttackAnimation")

var attack_sound = preload("res://hazards/enemies/gas_vent/assets/gas_vent.ogg")

func _ready():
    attack_animation.play("attack")
