## Kickable
## 
## Represents an object that can be kicked by the player in game.
## Whether this gets kicked or not is determined by the kickable property. This property is set by
## colliding with the player's kick hitbox. 

class_name Kickable

extends RigidBody2D

## Whether this object can be kicked or not
@export var kickable:bool = false
## How many frames to ignore gravity for after being kicked  
@export var ignore_gravity_frames_max:int = 1
## Sound to play when this object is kicked
@export var impact_sound:AudioStream = null
## The gravity_scale value to reset to after being kicked
@export var default_gravity_scale = 1.0

# Tracks how many frames that gravity has been ignored for. Adjust ignore_gravity_frames_max to
# change how long gravity is ignored for.
var ignore_gravity_frame_counter = 0

func _physics_process(_delta):
    if ignore_gravity_frame_counter == ignore_gravity_frames_max and ignore_gravity_frame_counter > 0:
        # Allow gravity to affect this object again if the ignore_gravity_frames_max has been reached.
        # Also check that ignore_gravity_frame_counter is greater than 0 to prevent this from being
        # called when not ignoring gravity.
        _respect_gravity()
    elif ignore_gravity_frame_counter > 0:
        ignore_gravity_frame_counter += 1

## Make this object kickable, which will allow it to be kicked by the entity if it's kick hitbox
## is currently colliding with this object.
func set_kickable(is_kickable):
    kickable = is_kickable

## Kick this object with the given kick_power, which will be applied to this object as an impulse.
func kick(kick_power: Vector2):
    # Stop the object from moving, which keeps its current movement from affecting the kick.
    set_axis_velocity(Vector2.ZERO)

    apply_central_impulse(kick_power)

    ignore_gravity_frame_counter = 1
    gravity_scale = 0

func _respect_gravity():
    # Restore gravity_scale to default value and reset ignore_gravity_frame_counter
    ignore_gravity_frame_counter = 0
    gravity_scale = default_gravity_scale

func _play_sound(sound):
    # Spawn a new AudioStreamPlayer2D and play the sound passed in to it. This is done because I want
    # to be able to play many impoact_sounds at once without them being interrupted by each other.
    var sound_player = AudioStreamPlayer2D.new()
    sound_player.set_stream(sound)
    sound_player.autoplay = true
    sound_player.max_distance = 200.0
    sound_player.position = position
    sound_player.connect('finished', Callable(sound_player, 'queue_free'))

    # Parent plays the sound so it's not tied to the object that spawned it and will continue to play
    # even if the object is destroyed.
    get_parent().add_child(sound_player)

func _on_body_entered(_body):
    _play_sound(impact_sound)
