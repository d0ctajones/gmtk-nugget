extends Node

var level_music = preload("res://music/Zander Noriega - Fight Them Until We Cant.mp3")

func _ready():
    load_level()
    spawn_player()

func spawn_player():
    var player = load("res://player/player.tscn")
    var player_node = player.instantiate()
    var player_spawn = $Level.get_node("PlayerSpawn").position

    player_node.position = player_spawn
    connect_player_signals(player_node)

    add_child(player_node)

func load_level():
    var level = load("res://levels/01/level.tscn")
    var level_instance = level.instantiate()

    add_child(level_instance)

    # play_music()

func connect_player_signals(player_node):
    $HUD.activate_player_hud(player_node)
    player_node.state_change.connect($HUD._update_player_stats)

    player_node.player_died.connect(handle_player_death)

func handle_player_death():
    get_tree().reload_current_scene()

func play_music():
    var sound_player = AudioStreamPlayer.new()
    sound_player.set_stream(level_music)
    sound_player.autoplay = true
    sound_player.set_volume_db(-25.0)
    sound_player.connect('finished', Callable(sound_player, 'start'))

    add_child(sound_player)
