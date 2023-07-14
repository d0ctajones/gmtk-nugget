extends RigidBody2D

@export var kickable:bool = false
@export var hit_reaction_delay:float = 0.2

@onready var animation_player = $AnimationPlayer
@onready var dialog_player = $DialogPlayer


var dialog_sounds = {
    greeting = {
        sound = preload("res://npc/french_fry_guy/sounds/find_my_other_half_please.ogg"),
        played = false
    },
    hit = [
        preload("res://npc/french_fry_guy/sounds/owow.ogg"),
        preload("res://npc/french_fry_guy/sounds/stop_it.ogg")
    ],
    success = preload("res://npc/french_fry_guy/sounds/yayyy.ogg")
}


func set_kickable(is_kickable):
    kickable = is_kickable
 
func kick(_kick_power):
    await get_tree().create_timer(hit_reaction_delay).timeout
    handle_dialog("hit")

func _on_area_2d_body_entered(body:Node2D):
    if body.name.contains("OtherHalf"):
        animation_player.play("fade_away")
        body.fade_away()

func handle_dialog(circumstance:String):
    if dialog_player.is_playing():
        pass
    elif circumstance == "meeting":
        if not dialog_sounds.greeting.played:
            dialog_player.set_stream(dialog_sounds.greeting.sound)
            dialog_player.play()
            dialog_sounds.greeting.played = true
    elif circumstance == "hit":
        var hit_sound = dialog_sounds.hit[randi() % dialog_sounds.hit.size()]
        dialog_player.set_stream(hit_sound)
        dialog_player.play()

func _on_player_detector_body_entered(_body:Node2D):
    handle_dialog("meeting")
