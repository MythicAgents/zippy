extends Node

func _on_tasking_exit(transport, task):
	transport.send(
		transport.create_task_response(
			true,
			true,
			task.get("id"),
			"So long, K. Bowser!",
			[
				[
					"Process Destroy",
					"zippy agent"
				]
			]
		)
	)
