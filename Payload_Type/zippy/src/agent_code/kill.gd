extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_kill(task):

	if task.has("command") and task.get("command") == "kill":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var status = OS.kill(parameters.get("pid"))
		var output = "Kill returned: %d" % status

		api.send_agent_response(
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
