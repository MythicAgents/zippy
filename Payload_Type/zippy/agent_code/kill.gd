extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_kill(task):

	if task.has("command") and task.get("command") == "kill":
		var parameters = parse_json(task.get("parameters"))
		var status = OS.kill(parameters.get("pid"))
		var output = "Kill returned: %d" % status

		api.agent_response(
			api.create_task_response(
				status == OK,
				true,
				task.get("id"),
				output
			)
		)
	else:
		pass
		# TODO: error state
