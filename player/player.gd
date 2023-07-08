extends KinematicBody2D

export (int) var max_ground_speed       = 250
export (int) var ground_acceleration    = 30
export (int) var ground_friction        = 50
export (int) var gravity                = 2
export (int) var max_fall_speed         = 700
export (int) var jump_speed             = 350
export (int) var air_move_speed         = 120
export (int) var air_acceleration       = 100
export (int) var air_friction           = 20
export (float) var vertical_jump_time   = 0.25
export (float) var no_jump_time         = 0.18
export (Vector2) var velocity           = Vector2.ZERO

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

################################################################################
# State Functions

func move_state(delta):
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("jump"):
        if has_node("no_jump_timer"):
            pass
        else:
            state = STATES.JUMP
            return

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1

    if input_vector != Vector2.ZERO:
        # Accelerate in the direction of the input_vector.x value
        velocity.x = lerp(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
    else:
        # Steadily apply ground_friction until x-axis speed is 0
        velocity.x = lerp(velocity.x, 0, ground_friction * delta)

    # Limit to max groundspeed
    velocity.x = clamp(velocity.x, -max_ground_speed, max_ground_speed)

func jump_state(delta):
    if has_node("jump_timer"):
        velocity.y = -jump_speed
    else:
        add_jump_timer()

    if Input.is_action_just_released("jump"):
        # Shorter jump height if space bar released early
        if has_node("jump_timer"):
            get_node("jump_timer").queue_free()
            state = STATES.FALL

    var input_vector = Vector2.ZERO

    # Allow player to preserve momentum by holding a direction
    if Input.is_action_pressed("move_right"):
        input_vector.x = 1
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1

    if input_vector != Vector2.ZERO:
        velocity.x = lerp(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
    else:
        velocity.x = lerp(velocity.x, 0, ground_friction * delta)

    velocity.x = clamp(velocity.x, -max_ground_speed, max_ground_speed)


func fall_state(delta):
    # Manages x-axis air control. Gravity application is in process_gravity
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1

    if input_vector != Vector2.ZERO:
        velocity.x = lerp(velocity.x, input_vector.x * air_move_speed, air_acceleration * delta)
    else:
        velocity.x = lerp(velocity.x, 0, air_friction * delta)

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

    # Test for collisions
    var collision = move_and_collide(velocity * delta, true, true, true)

    if collision:
        if state == STATES.FALL:
            if collision.normal.y <= -0.75:
                # Player touched the floor
                add_no_jump_timer()
                state = STATES.MOVE
        elif state == STATES.JUMP:
            if collision.normal.y >= 0.75:
                # Player hit head on ceiling
                state = STATES.FALL

    velocity = move_and_slide(velocity, Vector2(0, -1), true, 2, 0.75, true)

################################################################################
# Timer Functions

func add_no_jump_timer():
    # Prevent player from hitting jump for a moment after landing
    var timer = Timer.new()
    timer.name = "no_jump_time"
    timer.set_one_shot(true)
    timer.set_wait_time(vertical_jump_time)
    timer.connect('timeout', timer, 'queue_free')

    add_child(timer)
    timer.start()

func add_jump_timer():
    # Set timer that allows player to ingore gravity until vertical_jump_time passes
    var timer = Timer.new()
    timer.name = "jump_timer"
    timer.set_one_shot(true)
    timer.set_wait_time(vertical_jump_time)
    timer.connect('timeout', timer, 'queue_free')
    timer.connect('timeout', self, '_end_jump')

    add_child(timer)
    timer.start()

func _end_jump():
    state = STATES.FALL

################################################################################
# Main Game Loop Functions

func spawn(spawn_position):
    position = spawn_position
    velocity = Vector2.ZERO

