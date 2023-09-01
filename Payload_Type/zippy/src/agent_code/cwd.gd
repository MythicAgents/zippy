extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_cwd(task):

	if task.has("command") and task.get("command") == "cwd":

		api.send_agent_response(
			api.create_task_response(
				true,
				true,
				task.get("id"),
				OS.get_executable_path()
			)
		)
	else:
		pass
		# TODO: error state
