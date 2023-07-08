extends KinematicBody2D

export (int) var max_ground_speed       = 200
export (int) var ground_acceleration    = 50
export (int) var ground_friction        = 25
export (int) var gravity                = 12
export (int) var max_fall_speed         = 250
export (int) var jump_speed             = 350
export (int) var air_move_speed         = 50
export (int) var air_acceleration       = 100
export (int) var air_friction           = 50
export (float) var vertical_jump_time   = 0.2
export (float) var no_jump_yet_time     = 0.18
export (Vector2) var velocity           = Vector2.ZERO

# Possible player states
enum STATES {
    MOVE,
    JUMP,
    FALL,
}

export (STATES) var state = STATES.MOVE


func _physics_process(delta):
    if state != STATES.JUMP:
        respect_gravity(delta)

    match state:
        STATES.MOVE: move_state(delta)
        STATES.JUMP: jump_state(delta)
        STATES.FALL: fall_state(delta)

func move_state(delta):
    if Input.is_action_pressed("jump"):
        if has_node("landing_timer"):
            # Prevent the player from spamming jump too frequently based on no_jump_yet_time
            pass
        else:
            state = STATES.JUMP

    var input_vector = Vector2.ZERO

    # Get left or right movement input
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

    # Move and smootly go over collision
    velocity = move_and_slide(velocity)

func jump_state(delta):
    if has_node("jump_timer"):
        # Only create one jump timer
        pass
    else:
        # Set timer that allows player to ingore gravity until vertical_jump_time passes
        var timer = Timer.new()
        timer.name = "jump_timer"
        timer.set_one_shot(true)
        timer.set_wait_time(vertical_jump_time)
        timer.connect('timeout', timer, 'queue_free')
        timer.connect('timeout', self, '_end_jump')

        add_child(timer)
        timer.start()

    var input_vector = Vector2.ZERO

    # Allow player to preserve momentum by holding a direction
    if Input.is_action_pressed("move_right"):
        input_vector.x = 1
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1

    if input_vector != Vector2.ZERO:
        # Steadily move from no move speed to max speed based on ground_acceleration. Use the ground speed
        # variables to carry momentum until fall state
        velocity.x = lerp(velocity.x, input_vector.x * max_ground_speed, ground_acceleration * delta)
    else:
        # Steadily apply air_friction until x-axis speed is 0
        velocity.x = lerp(velocity.x, 0, air_friction * delta)

    # Negative speed go up
    velocity.y = -jump_speed

    # Detect collision from above the player in the y-axis. Set the state to the fall state
    var collision = move_and_collide(velocity * delta)

    if collision:
        var collision_direction = collision.normal

        if collision_direction.y >= 0:
            # Player hit their head
            velocity.y = 0
            state = STATES.FALL


func _end_jump():
    # After the jump_timer ends, endter the fall state
    state = STATES.FALL

func fall_state(delta):
    # Enable air control
    var input_vector = Vector2.ZERO

    if Input.is_action_pressed("move_right"):
        input_vector.x = 1
    if Input.is_action_pressed("move_left"):
        input_vector.x = -1

    # Move in the air according to air speed and ground_acceleration
    if input_vector != Vector2.ZERO:
        velocity.x = lerp(velocity.x, input_vector.x * air_move_speed, air_acceleration * delta)
    else:
        velocity.x = lerp(velocity.x, 0, air_friction * delta)

    # Limit x velocity to air control
    velocity.x = clamp(velocity.x, -air_move_speed, air_move_speed)

    # Detect collisions while falling. Only take action against a collision if it's in the y-axis
    var collision = move_and_collide(velocity * delta)

    if collision:
        var collision_direction = collision.normal

        if collision_direction.y != 0:
            velocity.y = 0

            # Character landed on something. Swap to move state
            state = STATES.MOVE
        else:
            velocity = move_and_slide(velocity)


func spawn(spawn_position):
    position = spawn_position
    velocity = Vector2.ZERO

func respect_gravity(delta):
    # Get to max fall speed by stepping up with gravity constant
    velocity.y = lerp(velocity.y, max_fall_speed, gravity * delta)
    # Limit fall speed to max fall speed
    velocity.y = clamp(velocity.y, 0 , max_fall_speed)

    # Move down and check for collisions
    var go_down = velocity * delta
    var collision = move_and_collide(go_down)

    if collision:
        # Get collision diections
        var collision_direction = collision.normal

        if collision_direction.y != 0:
            # If the collision is on the y axis, stop moving in the y axis
            velocity.y = 0

            if state == STATES.FALL and not has_node("landing_timer"):
                # If the player is falling and they don't having a landing timer, start a landing
                # timer. This prevents them from spamming jump when they land
                var timer = Timer.new()
                timer.name = "landing_timer"
                timer.set_one_shot(true)
                timer.set_wait_time(no_jump_yet_time)
                timer.connect('timeout', timer, 'queue_free')
                add_child(timer)
                timer.start()

            # Character landed on something. Swap to move state
            state = STATES.MOVE
