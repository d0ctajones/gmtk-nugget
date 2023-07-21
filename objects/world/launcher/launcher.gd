class_name Launcher

extends StaticBody2D

@onready var launch_box = get_node("launch_box")
@onready var animation_player = get_node("AnimationPlayer")
@onready var attack_timer = get_node("AttackTimer")

@export var attack_frequency: float = 2.0

func _ready():
    attack_timer.timeout.connect(Callable(_on_AttackTimer_timeout))
    attack_timer.wait_time = attack_frequency
    attack_timer.start()

func _on_AttackTimer_timeout():
    animation_player.play("launch")

func _on_launch():
    var bodies = launch_box.get_overlapping_bodies()

    for body in bodies:
        if body.has_method("kick"):
            body.kick(Vector2(0, -700))

    attack_timer.start()
