extends Node

var player_node = null

func _ready():
	load_level()
	spawn_player()

func spawn_player():
	var player = load("res://player/player.tscn")
	player_node = player.instance()
	var player_spawn = $Level.get_node("PlayerSpawn").position

	player_node.spawn(player_spawn)
	add_child(player_node)

func load_level():
	var level = load("res://level/level.tscn")
	var level_instance = level.instance()

	add_child(level_instance)
