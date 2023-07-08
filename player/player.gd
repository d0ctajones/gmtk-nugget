extends CharacterBody2D

@export var max_ground_speed: float     = 250.0
@export var ground_acceleration: float  = 30.0
@export var ground_friction: float      = 50.0
@export var gravity: float              = 2.0
@export var max_fall_speed: float       = 700.0
@export var jump_speed: float           = 350.0
@export var air_move_speed: float       = 120.0
@export var air_acceleration: float     = 100.0
@export var air_friction: float         = 20.0
@export var vertical_jump_time: float   = 0.25


# Possible player states
enum STATES {
    MOVE,
    JUMP,
    FALL,
}

var state = STATES.MOVE

func _physics_process(delta):
    match state:
        STATES.MOVE: move_state(delta)
        STATES.JUMP: jump_state(delta)
        STATES.FALL: fall_state(delta)

    move(delta)

func flip_sprite():
    if velocity.x < 0:
        $Sprite2D.flip_h = true
    elif velocity.x > 0:
        $Sprite2D.flip_h = false

################################################################################
# State Functions

func move_state(delta):
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0

    if input_vector != Vector2.ZERO:
        # Accelerate in the direction of the input_vector.x value
        velocity.x = lerp(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
        flip_sprite()
    else:
        # Steadily apply ground_friction until x-axis speed is 0
        velocity.x = lerp(velocity.x, 0.0, ground_friction * delta)

    # Limit to max groundspeed
    velocity.x = clamp(velocity.x, -max_ground_speed, max_ground_speed)

    if Input.is_action_just_pressed("jump") and is_on_floor():
        state = STATES.JUMP

func jump_state(delta):
    if Input.is_action_pressed("jump"):
        if has_node("jump_timer"):
            pass
        else:
            add_jump_timer()

    var input_vector = Vector2.ZERO

    # Allow player to preserve momentum by holding a direction
    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0

    if input_vector != Vector2.ZERO:
        velocity.x = lerp(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
        flip_sprite()
    else:
        velocity.x = lerp(velocity.x, 0.0, ground_friction * delta)

    velocity.y = -jump_speed
    velocity.x = clamp(velocity.x, -max_ground_speed, max_ground_speed)

    if Input.is_action_just_released("jump"):
        # Shorter jump height if space bar released early
        if has_node("jump_timer"):
            get_node("jump_timer").queue_free()
            state = STATES.FALL


func fall_state(delta):
    # Manages x-axis air control. Gravity application is in process_gravity
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1.0
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1.0

    if input_vector != Vector2.ZERO:
        velocity.x = lerp(velocity.x, input_vector.x * air_move_speed, air_acceleration * delta)
    else:
        velocity.x = lerp(velocity.x, 0.0, air_friction * delta)

    velocity.x = clamp(velocity.x, -air_move_speed, air_move_speed)

################################################################################
# Gravity and Move

func process_gravity(delta):
    if state == STATES.JUMP or is_on_floor():
        # Don't apply gravity if currently jumping or touching the floor
        return

    velocity.y = lerp(velocity.y, max_fall_speed, gravity * delta)
    velocity.y = clamp(velocity.y, 0, max_fall_speed)


func move(delta):
    process_gravity(delta)
    move_and_slide()

    if state == STATES.FALL:
        if is_on_floor():
            state = STATES.MOVE

    elif state == STATES.JUMP:
        if is_on_ceiling_only():
            if has_node("jump_timer"):
                get_node("jump_timer").queue_free()
            state = STATES.FALL

################################################################################
# Timer Functions

func add_no_jump_timer():
    # Prevent player from hitting jump for a moment after landing
    var timer = Timer.new()
    timer.name = "no_jump_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(vertical_jump_time)
    timer.connect('timeout', Callable(timer, 'queue_free'))

    add_child(timer)
    timer.start()

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

func _end_jump():
    state = STATES.FALL
