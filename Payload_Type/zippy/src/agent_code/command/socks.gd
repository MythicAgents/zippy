extends Node

func _on_tasking_socks(transport, task):

	if task.has("command") and task.get("command") == "socks":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var sleep_duration = float(parameters.get("duration"))
		var output = "Sleeping %d seconds" % sleep_duration

		transport.send(
			transport.create_task_response(
				!is_nan(sleep_duration),
				true,
				task.get("id"),
				output
			)
		)
	else:
		pass
		# TODO: error state
