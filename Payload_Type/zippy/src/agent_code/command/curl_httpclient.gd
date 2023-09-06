extends HTTPRequest

class_name CurlHTTPClient

@export var transfer:Node = null
@export var transport:Node = null
@export var task_id:String = ""
@export var request_url:String = ""

func _init(Transport, Transfer, id, url):
	transport = Transport
	transfer = Transfer
	task_id = id
	request_url = url

func http_request_completed(result, response_code, headers, body):
	var output = "HTTP %d\n\n"

	for header in headers:
		output += "%s\n" % header

	output += "\n%s"

	if result != HTTPRequest.RESULT_SUCCESS:
		output = "Failed to fetch... %s\n%d\n" % [body, response_code]
		body = null

	transfer.on_tasking_download_buffer(transport, task_id, request_url, output, body)
