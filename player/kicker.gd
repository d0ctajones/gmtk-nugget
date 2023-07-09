extends Area2D



signal update_kick_list(action, body)

func _on_body_entered(body):
    if body.has_method("set_kickable"):
        body.set_kickable(true)
        emit_signal("update_kick_list", "add", body)

func _on_body_exited(body):
    if body.has_method("set_kickable"):
        body.set_kickable(false)
        emit_signal("update_kick_list", "remove", body)
