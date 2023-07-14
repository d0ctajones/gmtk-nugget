extends RigidBody2D

@onready var animation_player = $AnimationPlayer

func _on_area_2d_body_entered(body:Node2D):
    if body.name.contains("OtherHalf"):
        animation_player.play("fade_away")
        body.fade_away()