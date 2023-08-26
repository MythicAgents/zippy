extends Node

func _ready():
	pass

func _on_Agent_checkin(data):
	# {action:checkin, decryption_key:, encryption_key:, id:4da40eb1-a0ad-4cec-a443-d7083edd2918, status:success}

	if data.has("payload") and data.get("payload").has("id"):
		$".".get_parent().get_node("config").set_callback_uuid(data.get("payload").get("id"))
		$".".get_parent().get_node("api").checkin()
		print("checking complete!")
	else:
		print("Checkin failed? ", data)
