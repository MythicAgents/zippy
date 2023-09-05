extends Node

func _on_tasking_socks(transport, sock):
	transport.handle_socks(sock)
