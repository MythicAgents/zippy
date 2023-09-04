extends Node

func _on_tasking_whoami(transport, task):
	var exit_code = 0
	var output = [OS.get_environment("USERNAME")]
	var artifact = []
	
	if output.size() == 0:
		exit_code = OS.execute("whoami", [], output, true, false)
		artifact.append([
			"Process Create",
			"whoami"
		])

		if exit_code == 0:
			output = output.replace("\n", "")

	transport.send(
		transport.create_task_response(
			exit_code == 0,
			true,
			task.get("id"),
			output[0],
			artifact
		)
	)
