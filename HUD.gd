extends CanvasLayer

@onready var player_status_display = get_node("PlayerStats")

var base_player_stats_string = "NUGGET %s"

func _update_player_stats_state(state):
    $PlayerStats.text = base_player_stats_string % state
