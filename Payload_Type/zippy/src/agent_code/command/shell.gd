extends Node


func _on_tasking_shell(transport, task):
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var command = parameters.get("command")
	var arguments = parameters.get("arguments")
	var output = ["Failed to execute command %s %s" % [command, arguments]]
	print_debug("executing the following command and arguments")
	print_debug(command)
	print_debug(arguments)
	print_debug("")
	var exit_code = OS.execute(command, arguments, output, true, false)

	transport.send(
		transport.create_task_response(
			exit_code == 0,
			true,
			task.get("id"),
			output[0],
			[
				[
					"Process Create",
					command + " " + " ".join(PackedStringArray(arguments))
				]
			]
		)
	)
