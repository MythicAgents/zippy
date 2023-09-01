import shlex

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class SpawnArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):

        if len(self.command_line.strip()) == 0:
            raise ValueError("Really - what are you doing?")

        args = shlex.split(self.command_line)

        self.add_arg("command", args[0], ParameterType.String)
        self.add_arg("arguments", args[1:], ParameterType.Array)


class ShellCommand(CommandBase):
    cmd = "spawn"
    needs_admin = False
    help_cmd = "spawn {command}"
    description = "Execute a command with in a detached process"
    version = 1
    author = "@ArchiMoebius"
    attackmapping = ["T1059.004"]
    argument_class = SpawnArguments
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Linux, SupportedOS.Windows],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        resp = await MythicRPC().execute(
            "create_artifact",
            task_id=task.id,
            artifact="{}".format(task.args.command_line),
            artifact_type="Process Create",
        )
        task.display_params = f'Requesting detached process to spawn with {task.args.get_arg("command")} {task.args.get_arg("arguments")}'

        return task

    async def process_response(self, response: AgentResponse):
        pass
