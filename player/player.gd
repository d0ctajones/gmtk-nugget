extends CharacterBody2D

@export var max_ground_speed: float     = 300.0
@export var ground_acceleration: float  = 2500.0
@export var ground_friction: float      = 2000.0
@export var gravity: float              = 3000.0
@export var max_fall_speed: float       = 5000.0
@export var jump_speed: float           = 400.0
@export var air_move_speed: float       = 200.0
@export var air_acceleration: float     = 1000.0
@export var air_friction: float         = 300.0
@export var vertical_jump_time: float   = 0.2
@export var kick_interval: float        = 0.2

@onready var kicker = get_node("Kicker")

var hit_sounds = [
    preload("res://player/ouch.ogg")
]

var attack_sounds = {
    "vertical": preload("res://player/nyah_01.ogg"),
    "horizontal": preload("res://player/hwah_01.ogg")
}


var talk_crap = [
    preload("res://player/yeah.ogg"),
    preload("res://player/take_that_beer.ogg")
]

var found_beer = false
var found_beer_sound = preload("res://player/fizzy_fizzy_beer.ogg")

var found_liquor = false
var found_liquor_sound = preload("res://player/lucky_day_liquor.ogg")

var landing_sound = preload("res://player/moist_impact.ogg")
var head_impact_sound = preload("res://player/hit_head_deep.ogg")

var status = {
    "HEALTH": 5
}

# Possible player states
enum STATES {
    MOVE,
    JUMP,
    FALL,
}

signal state_change(state)
signal health_changed
signal player_died

var current_state = STATES.MOVE

var kick_list = {}

func _ready():
    $AnimationPlayer.play("move_right")

    $Kicker.update_kick_list.connect(update_kick_list)

func _physics_process(delta):
    if Input.is_action_just_pressed("kick_vertical") :
        kick("vertical")
    elif Input.is_action_just_pressed("kick_horizontal"):
        kick("horizontal")

    change_state(current_state)

    match current_state:
        STATES.MOVE: move_state(delta)
        STATES.JUMP: jump_state(delta)
        STATES.FALL: fall_state(delta)

    move(delta)

func kick(kick_type):
    if has_node("kick_timer"):
        pass
    else:
        add_kick_timer()

    var x_direction = 0

    var kick_x_velocity = 0
    var kick_y_velocity = 0

    if $AnimationPlayer.current_animation == "move_left":
        x_direction = -1
    else:
        x_direction = 1

    if kick_type == "horizontal":
        kick_x_velocity = x_direction * 400
        kick_y_velocity = -200
    elif kick_type == "vertical":
        kick_y_velocity = -400
        if current_state == STATES.MOVE:
            if velocity == Vector2.ZERO:
                kick_x_velocity = 0
            else:
                kick_x_velocity = x_direction * 150

    if current_state in [ STATES.JUMP, STATES.FALL ]:
        kick_y_velocity = kick_y_velocity - 150

    play_sound(attack_sounds[kick_type])
    for body in kick_list.values():
        body.kick(Vector2(kick_x_velocity, kick_y_velocity))

################################################################################
# State Functions

func move_state(delta):
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
        flip_sprite("right")
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0
        flip_sprite("left")

    if input_vector != Vector2.ZERO:
        # Accelerate in the direction of the input_vector.x value
        velocity.x = move_toward(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
    else:
        # Steadily apply ground_friction until x-axis speed is 0
        velocity.x = move_toward(velocity.x, 0, ground_friction * delta)

    # Limit to max groundspeed
    velocity.x = clamp(velocity.x, -max_ground_speed, max_ground_speed)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        change_state(STATES.JUMP)

func jump_state(delta):
    if has_node("jump_timer"):
        pass
    else:
        add_jump_timer()

    var input_vector = Vector2.ZERO

    # Allow player to preserve momentum by holding a direction
    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
        flip_sprite("right")
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0
        flip_sprite("left")

    if input_vector != Vector2.ZERO:
        velocity.x = move_toward(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, air_friction * delta)

    velocity.y = -jump_speed
    velocity.x = clamp(velocity.x, -max_ground_speed, max_ground_speed)

    if Input.is_action_just_released("jump"):
        # Shorter jump height if space bar released early
        if has_node("jump_timer"):
            get_node("jump_timer").queue_free()
            change_state(STATES.FALL)

func fall_state(delta):
    # Manages x-axis air control. Gravity application is in process_gravity
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
        flip_sprite("right")
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0
        flip_sprite("left")

    if input_vector != Vector2.ZERO:
        velocity.x = move_toward(velocity.x, input_vector.x * air_move_speed, air_acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, air_friction * delta)

    velocity.x = clamp(velocity.x, -air_move_speed, air_move_speed)

################################################################################
# Gravity and Move

func process_gravity(delta):
    if current_state == STATES.JUMP or is_on_floor():
        # Don't apply gravity if currently jumping or touching the floor
        return

    velocity.y = move_toward(velocity.y, max_fall_speed, gravity * delta)
    velocity.y = clamp(velocity.y, -jump_speed, max_fall_speed)

func move(delta):
    process_gravity(delta)
    move_and_slide()

    if current_state == STATES.MOVE:
        if not is_on_floor():
            change_state(STATES.FALL)

    elif current_state == STATES.FALL:
        if is_on_floor():
            change_state(STATES.MOVE)
            play_sound(landing_sound)
        elif is_on_ceiling():
            play_sound(head_impact_sound)

    elif current_state == STATES.JUMP:
        if is_on_ceiling_only():
            play_sound(head_impact_sound)
            if has_node("jump_timer"):
                get_node("jump_timer").queue_free()
            change_state(STATES.FALL)

################################################################################
# Player Actions

func change_state(state):
    var previous_state = current_state
    current_state = state

    if previous_state != current_state:
        state_change.emit()

func flip_sprite(direction):
    if direction == "left":
        $AnimationPlayer.play("move_left")
    elif direction == "right":
        $AnimationPlayer.play("move_right")

func update_kick_list(action, body):
    if action ==  "add":
        if not found_beer:
            if body.name.contains("Beer"):
                found_beer = true
                play_sound(found_beer_sound, 5.0)
        if not found_liquor:
            if body.name.contains("Liquor"):
                found_liquor = true
                play_sound(found_liquor_sound, 15.0)
        kick_list[body.name] = body
    else:
        kick_list.erase(body.name)

################################################################################
# Value Updaters and Getters

func get_current_state():
    return STATES.keys()[current_state]

func _on_hurtbox_body_entered(body):
    if body.has_method("deal_damage"):
        take_hit(body.deal_damage())
        state_change.emit()

func play_sound(sound, db=1.0):
    var sound_player = AudioStreamPlayer.new()
    sound_player.set_stream(sound)
    sound_player.autoplay = true
    sound_player.set_volume_db(db)
    sound_player.connect('finished', Callable(sound_player, 'queue_free'))

    get_parent().add_child(sound_player)

func take_hit(damage_amount):
    status["HEALTH"] = status["HEALTH"] - damage_amount
    state_change.emit()

    play_sound(hit_sounds[0])

    if status["HEALTH"] <= 0:
        player_died.emit()

################################################################################
# Timer Functions

func add_jump_timer():
    # Set timer that allows player to ingore gravity until vertical_jump_time passes
    var timer = Timer.new()
    timer.name = "jump_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(vertical_jump_time)
    timer.connect('timeout', Callable(timer, 'queue_free'))
    timer.connect('timeout', Callable(self, '_end_jump'))

    add_child(timer)
    timer.start()

func add_kick_timer():
    var timer = Timer.new()
    timer.name = "kick_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(kick_interval)
    timer.connect('timeout', Callable(timer, 'queue_free'))

    add_child(timer)
    timer.start()

func _end_jump():
    change_state(STATES.FALL)
