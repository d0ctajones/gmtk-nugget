extends CharacterBody2D

@export var ground_speed_max: float     = 300.0
@export var ground_acceleration: float  = 2500.0
@export var ground_friction: float      = 2000.0
@export var gravity: float              = 3000.0
@export var fall_speed_max: float       = 5000.0
@export var jump_speed_vertical: float  = 400.0
@export var jump_frames_max: int        = 15
@export var jump_frames_min: int        = 2
@export var air_move_speed: float       = 200.0
@export var air_acceleration: float     = 1000.0
@export var air_friction: float         = 300.0
@export var vertical_jump_time: float   = 0.2
@export var kick_cooldown: float        = 0.3
@export var dash_frames: float          = 8
@export var dash_speed: float           = 1100.0
@export var dash_cooldown: float        = 0.3

@onready var kicker = get_node("Kicker")
@onready var hurtbox = get_node("Hurtbox")
@onready var dialog_player = get_node("DialogPlayer")

signal state_change(state)
signal health_changed
signal player_died

var action_sounds = {
    landing = preload("res://player/sounds/moist_impact.ogg"),
    head_impact = preload("res://player/sounds/hit_head_deep.ogg"),
    attack = [
        preload("res://player/sounds/nyah_01.ogg"),
        preload("res://player/sounds/hwah_01.ogg")
    ],
}

var dialog_sounds = {
    hit = [
        preload("res://player/sounds/ouch.ogg")
    ],
    talk_crap = [
        preload("res://player/sounds/yeah.ogg"),
        preload("res://player/sounds/take_that_beer.ogg")
    ],
    found_beer = {
        sound = preload("res://player/sounds/fizzy_fizzy_beer.ogg"),
        played = false
    },
    found_liquor = {
        sound = preload("res://player/sounds/lucky_day_liquor.ogg"),
        played = false
    },
}


enum STATES {
    MOVE,
    JUMP,
    FALL,
    DASH,
}

var kick_list = {}
var status = {
    "HEALTH": 5
}

var current_state = STATES.MOVE
var dash_frame_counter = 0
var jump_frame_counter = 0

################################################################################
# _Ready and _Physics_Process

func _ready():
    $AnimationPlayer.play("move_right")

    $Kicker.update_kick_list.connect(update_kick_list)

func _physics_process(delta):
    if Input.is_action_just_pressed("kick_vertical") :
        kick("vertical")
    elif Input.is_action_just_pressed("kick_horizontal"):
        kick("horizontal")

    if Input.is_action_just_pressed("dash"):
        if not has_node("dash_cooldown_timer"):
            change_state(STATES.DASH)

    match current_state:
        STATES.MOVE: move_state(delta)
        STATES.JUMP: jump_state(delta)
        STATES.FALL: fall_state(delta)
        STATES.DASH: dash_state()

    move(delta)

################################################################################
# State Functions

func dash_state():
    # Dash in the direction the player is facing. Don't allow jumping or dashing again until the
    # dash frames are over. Remove the hurtbox while dashing. Base the dash direction on the current
    # animation.
    if has_node("dash_cooldown"):
        pass
    else:
        add_dash_cooldown_timer()

        if has_node("Hurtbox"):
            remove_child(hurtbox)

    if dash_frame_counter < dash_frames:
        dash_frame_counter += 1

        var input_vector = Vector2.ZERO

        if $AnimationPlayer.current_animation == "move_right":
            input_vector.x = 1.0
        elif $AnimationPlayer.current_animation == "move_left":
            input_vector.x = -1.0

        velocity.y = 0
        velocity.x = input_vector.x * dash_speed
    else:
        _end_dash()


func move_state(delta):
    # Handle x movement on the ground and flip sprite to face direction of movement. Allow jumping
    # and dashing. If not moving, apply ground_friction until x-axis speed is 0.
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
        flip_sprite("right")
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0
        flip_sprite("left")

    if input_vector != Vector2.ZERO:
        velocity.x = move_toward(velocity.x, input_vector.x * ground_speed_max, ground_acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, ground_friction * delta)

    velocity.x = clamp(velocity.x, -ground_speed_max, ground_speed_max)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        change_state(STATES.JUMP)

func jump_state(delta):
    # Set y velocity to jump_speed_vertical and allow player to move horizontally in the air. Also
    # allow player to end the jump early by releasing the jump button. Sprite is flipped to face
    # input direction.
    jump_frame_counter += 1

    if jump_frame_counter == jump_frames_max:
        _end_jump()
        return

    var input_vector = Vector2.ZERO

    # Allow player to preserve momentum by holding a direction
    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
        flip_sprite("right")
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0
        flip_sprite("left")

    if input_vector != Vector2.ZERO:
        velocity.x = move_toward(velocity.x, input_vector.x * ground_speed_max, ground_acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0, air_friction * delta)

    velocity.y = -jump_speed_vertical
    velocity.x = clamp(velocity.x, -ground_speed_max, ground_speed_max)

    if jump_frame_counter >= jump_frames_min and Input.is_action_just_released("jump"):
        # Make sure a minimum number of frames have passed before allowing the player to end the
        # jump early. Makes it easier to do short hops.
        _end_jump()

func fall_state(delta):
    # Handle x movement in the air and flip sprite to face direction of movement
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

func change_state(state):
    # Change the current state and emit signal to update HUD
    current_state = state
    state_change.emit()

func _end_jump():
    # Reset jump frame counter and change state to fall
    jump_frame_counter = 0
    change_state(STATES.FALL)

func _end_dash():
    # TODO: Change this to animation player
    # Reset dash frame counter and add hurtbox back to player
    dash_frame_counter = 0
    if not has_node("Hurtbox"):
        add_child(hurtbox)

    velocity.x = 0
    if is_on_floor():
        change_state(STATES.MOVE)
    else:
        change_state(STATES.FALL)


################################################################################
# Gravity, Movement, and Action Functions

func move(delta):
    # Apply gravity and move_and_slide. Deals with changing between states based on floor and
    # ceiling collisions.

    if current_state == STATES.MOVE:
        if not is_on_floor():
            change_state(STATES.FALL)

    elif current_state == STATES.FALL:
        # Handle gravity and limit fall speed
        velocity.y = move_toward(velocity.y, fall_speed_max, gravity * delta)
        velocity.y = clamp(velocity.y, -jump_speed_vertical, fall_speed_max)

        if is_on_floor():
            change_state(STATES.MOVE)
            handle_action_sounds("landing")
        elif is_on_ceiling():
            handle_action_sounds("head_impact")

    elif current_state == STATES.JUMP:
        if is_on_ceiling_only():
            handle_action_sounds("head_impact")
            _end_jump()

    move_and_slide()


func kick(kick_type):
    # Kick in the direction of movement. If not moving, kick in the direction the player is facing.
    # Don't kick if the kick cooldown timer is active.
    if not has_node("kick_cooldown_timer"):
        add_kick_cooldown_timer()

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

        handle_action_sounds("attack")

        for body in kick_list.values():
            body.kick(Vector2(kick_x_velocity, kick_y_velocity))

################################################################################
# Sound Functions

func handle_dialog(circumstance:String):
    # Play a dialog sound based on the current circumstance. Only one dialog sound can play at a
    # time. If a dialog sound is already playing, do nothing.
    var dialog_sound = null

    if dialog_player.is_playing():
        return
    elif circumstance == "hit":
        dialog_sound = dialog_sounds.hit[randi() % dialog_sounds.hit.size()]
    elif circumstance == "talk_crap":
        dialog_sound = dialog_sounds.talk_crap[randi() % dialog_sounds.talk_crap.size()]
    elif circumstance == "found_beer":
        if not dialog_sounds.found_beer.played:
            dialog_sound = dialog_sounds.found_beer.sound
            dialog_sounds.found_beer.played = true
    elif circumstance == "found_liquor":
        if not dialog_sounds.found_liquor.played:
            dialog_sound = dialog_sounds.found_liquor.sound
            dialog_sounds.found_liquor.played = true
    else:
        return

    dialog_player.set_stream(dialog_sound)
    dialog_player.play()

func handle_action_sounds(circumstance:String):
    # Play a sound based on the current action. These sounds are not interruptable by other sounds
    # and will play until finished. This is separate from dialog sounds so that they can be played
    # simultaneously.
    var action_sound = null

    if circumstance == "attack":
        action_sound = action_sounds.attack[randi() % action_sounds.attack.size()]
    elif circumstance == "landing":
        action_sound = action_sounds.landing
    elif circumstance == "head_impact":
        action_sound = action_sounds.head_impact
    else:
        return

    var action_sound_player = AudioStreamPlayer.new()
    action_sound_player.set_stream(action_sound)
    get_parent().add_child(action_sound_player)

    action_sound_player.play()

################################################################################
# Animation Functions

func flip_sprite(direction):
    # Flip the sprite to face the direction of movement
    if direction == "left":
        $AnimationPlayer.play("move_left")
    elif direction == "right":
        $AnimationPlayer.play("move_right")

################################################################################
# Value Updaters and Getters

func get_current_state():
    # Return the current state as a string
    return STATES.keys()[current_state]

func _on_hurtbox_body_entered(body):
    # If the colliding body has a deal_damage method, take damage and emit signal to update HUD
    if body.has_method("deal_damage"):
        take_hit(body.deal_damage())
        state_change.emit()

func take_hit(damage_amount):
    # TODO: Add invincibility frames
    # TODO: Add knockback
    # Reduce health by damage_amount and emit signal to update HUD. Play hit sound and check for death
    status["HEALTH"] = status["HEALTH"] - damage_amount
    state_change.emit()

    handle_dialog("hit")

    if status["HEALTH"] <= 0:
        player_died.emit()

func update_kick_list(action, body):
    # Add or remove bodies from the kick list depending on the action
    if action ==  "add":
        if body.name.contains("Beer"):
            handle_dialog("found_beer")
        elif body.name.contains("Liquor"):
            handle_dialog("found_liquor")
        kick_list[body.name] = body
    else:
        kick_list.erase(body.name)

################################################################################
# Timer Functions

func add_kick_cooldown_timer():
    # Prevent player from kicking again until cooldown is over
    var timer = Timer.new()
    timer.name = "kick_cooldown_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(kick_cooldown)
    timer.autostart = true
    timer.connect('timeout', Callable(timer, 'queue_free'))

    add_child(timer)

func add_dash_cooldown_timer():
    # Prevent player from dashing again until cooldown is over
    var timer = Timer.new()
    timer.name = "dash_cooldown_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(dash_cooldown)
    timer.autostart = true
    timer.connect('timeout', Callable(timer, 'queue_free'))

    add_child(timer)
