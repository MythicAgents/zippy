extends Node

class_name TransportSocks

@export var transport:Node = null

signal disconnected

const VER = 0x05
const M_NOAUTH = 0x00
const M_NOTAVAILABLE = 0xff
const CMD_CONNECT = 0x01
const ATYP_IPV4 = 0x01
const ATYP_DOMAINNAME = 0x03

# https://www.rfc-editor.org/rfc/rfc1928 ==> 6. Replies
const REP_SUCCEEDED = 0x00
const REP_SERVER_FAILURE = 0x01 # general SOCKS server failure
const REP_CONNECT_BLOCKED = 0x02 #  connection not allowed by ruleset
const REP_NETWORK_UNREACHABLE = 0x03 # Network unreachable
const REP_HOST_UNREACHABLE = 0x04 # Host unreachable
const REP_CONNECTION_REFUSED = 0x05 # Connection refused
const REP_TTL_EXPIRED = 0x06 # TTL expired
const REP_COMMAND_FAILURE = 0x07 # Command not supported
const REP_ADDRESS_FAILURE = 0x08 # Address type not supported
# const X'09' to X'FF' unassigned

var _client:StreamPeerTCP = null
var _time = 0
var _heartbeat_period = 0.1
var connect_attempt = 0
var outbound = []
var do_exit = false
var _addr = "127.0.0.1"
var _port = 0
var server_id
var _handshake_complete = false


# https://www.rfc-editor.org/rfc/rfc1928
func parse_socks5_request(b64data:String):
	var rep = REP_SERVER_FAILURE
	var reply = PackedByteArray([VER, rep, 0x00, ATYP_IPV4, 0x00,0x00,0x00,0x00,0x00,0x00])

	if b64data == null:
		print_debug("bad b64data for parse_socks5_request")
		print_debug("reply: ", reply)
		a2m(reply)
		return false

	var data:PackedByteArray = Marshalls.base64_to_raw(b64data)

	if data == null:
		print_debug("bad data for parse_socks5_request")
		print_debug("reply: ", reply)
		a2m(reply)
		return false

	if (data[0] != VER or data[1] != CMD_CONNECT or data[2] != 0x00):
		print_debug("bad header for parse_socks5_request")
		print_debug("reply: ", reply)
		a2m(reply)
		return false

	if data[3] == ATYP_IPV4:
		_addr = "%d.%d.%d.%d" % [data.decode_u8(4), data.decode_u8(5), data.decode_u8(6), data.decode_u8(7)]
		_port = PackedByteArray([data.decode_u8(9), data.decode_u8(8)]).decode_u16(0)
	elif data[3] == ATYP_DOMAINNAME:
		var sz_domain_name = data.decode_u8(4)
		_addr = data.slice(5, 5 + sz_domain_name)
		_port = data.slice(5 + sz_domain_name, 5 + sz_domain_name + 2)
		_port = PackedByteArray([_port.decode_u8(1), _port.decode_u8(0)]).decode_u16(0)
	else:
		print_debug("reply: ", reply)
		a2m(reply)
		return false

	_client = StreamPeerTCP.new()

	print_debug("connect to host: %s:%d", [_addr, _port])

	var ret = _client.connect_to_host(_addr, _port)
	if ret == OK:
		var poll_status
		var status = _client.get_status()

		while status == StreamPeerTCP.STATUS_CONNECTING:
			status = _client.get_status()
			poll_status = _client.poll()
			print_debug("...")
			await get_tree().create_timer(1).timeout
		
		print_debug("ret: ", ret)
		print_debug("poll_status: ", poll_status)
		print_debug("status: ", status)

		if poll_status == OK and status == StreamPeerTCP.STATUS_CONNECTED:
			var peerIP:String = _client.get_connected_host() # gdscript is dumb...there is no 'get_local_host()'...why...
			var peerIPSplit:PackedStringArray = peerIP.split(".")
			peerIPSplit.reverse()
			var idx = 4
			for octet in peerIPSplit:
				reply.encode_u8(idx, int(octet))
				idx += 1
			var peerPort:PackedByteArray = var_to_bytes(_client.get_local_port())

			print_debug("connected from : %s %d" % [peerIP, _client.get_local_port()])

			reply.encode_u8(1, REP_SUCCEEDED)

			# our IP + our PORT...so nasty...assumes we're little endian...todo...
			reply.encode_u8(8, peerPort[1])
			reply.encode_u8(9, peerPort[0])
			
			_handshake_complete = true
		else:
			match poll_status:
				ERR_CONNECTION_ERROR:
					reply[1] = REP_HOST_UNREACHABLE
					print_debug("failed to reach host")
			match status:
				StreamPeerTCP.STATUS_NONE:
					reply[1] = REP_HOST_UNREACHABLE
					print_debug("failed to reach host")
				StreamPeerTCP.STATUS_ERROR:
					reply[1] = REP_HOST_UNREACHABLE
					print_debug("error reaching host")

			ret = ERR_CANT_CONNECT

	print_debug("reply: ", reply)

	a2m(reply, ret != OK)

	return ret == OK


func _init(Transport, id):
	transport = Transport
	server_id = id
	connect_attempt = 3


func send(b64data):

	if b64data == null:
		return

	outbound.append(Marshalls.base64_to_raw(b64data))

func a2e():
	# drain our outbound queue...
	while outbound.size() > 0:
		var packet = outbound.pop_front() # FIFO it!

		if OK != _client.put_data(packet):
			print_debug("oh-snap, something went awry w/ : ", packet)
			pass


func a2m(data, exit=false):
	if data != null:
		data = Marshalls.raw_to_base64(data)

	return transport.protocol.send(JSON.stringify({
		"action": "post_response",
		"responses": [],
		"socks": [
			{
				"exit": exit,
				"server_id": server_id,
				"data": data
			}
		]
	}), true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_time += delta

	if _time > _heartbeat_period and _handshake_complete:

		if client_is_connected() == 1:
			
			if _client.get_available_bytes() > 0:
				var data = _client.get_partial_data(2048)

				if data is Array and data[0] == OK:
					a2m(data[1])
				else:
					print_debug("something went wrong reading remote: ", data)
					pass

			a2e()
		# reset our heartbeat timer
		_time = 0

func client_disconnect():
	if client_is_connected() == 1:
		_client.disconnect_from_host()

	a2m(null, true)

	# halt the _process callback each frame
	set_process(false)

func client_is_connected():
	if _client == null:
		return -1

	var poll_status = _client.poll()

	if poll_status != OK:
		print_debug("poll_status: ", poll_status)
		return poll_status

	var status = _client.get_status()

	if status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
		return -1
	elif status == StreamPeerTCP.STATUS_CONNECTED:
		return 1
	else:
		print_debug("SOCKS client in unknown state", status)
		return 0
