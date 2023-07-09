extends CanvasLayer

@onready var player_status_display = get_node("PlayerStats")

var display_string = "NUGGET %s\nHealth: %s"
var player_node = null
var player_health = null
var player_state = null

func activate_player_hud(player):
    player_node = player
    get_player_state()

func get_player_state():
    player_state = player_node.get_current_state()
    player_health = player_node.status["HEALTH"]

    $PlayerStats.text = display_string % [ player_state, player_health ]

func _update_player_stats():
    get_player_state()
