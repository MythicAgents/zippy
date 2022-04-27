extends Node2D

var time = 0
var time_period = 1

signal verify_username_password

func _ready():
	$".".hide()

func reset():
	$ScreenContainer/MessageContainer/CredentialContainer/UsernameInput.text = ""
	$ScreenContainer/MessageContainer/CredentialContainer/PasswordInput.text = ""

	$ScreenContainer/MessageContainer/CredentialContainer/VerifyButton.disabled = true

func _process(delta):
	time += delta

	if time > time_period:

		if $ScreenContainer/MessageContainer/CredentialContainer/UsernameInput.text != "" and $ScreenContainer/MessageContainer/CredentialContainer/PasswordInput.text != "":
			$ScreenContainer/MessageContainer/CredentialContainer/VerifyButton.disabled = false
		else:
			$ScreenContainer/MessageContainer/CredentialContainer/VerifyButton.disabled = true

func _on_VerifyButton_button_up():
	emit_signal("verify_username_password", $ScreenContainer/MessageContainer/CredentialContainer/UsernameInput.text, $ScreenContainer/MessageContainer/CredentialContainer/PasswordInput.text)
