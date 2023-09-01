extends Node

var api
var agent

func _ready():
	api = $".".get_parent().get_node("api")
	agent = $".".get_parent().get_parent().get_node("Agent")


func _on_tasking_exit(task):

	if task.has("command") and task.get("command") == "exit":
		agent.do_exit = true
		agent.exiting = true

		api.send_agent_response(
			api.create_task_response(
				true,
				true,
				task.get("id"),
				"Any last words?",
				[
					[
						"Process Destroy",
						"zippy agent"
					]
				]
			)
		)
	else:
		pass
		# TODO: error state
