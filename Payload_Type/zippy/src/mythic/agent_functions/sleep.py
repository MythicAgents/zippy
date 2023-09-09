import shlex

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class SleepArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        if len(self.command_line.strip()) == 0:
            raise ValueError(
                "Really - what are you doing? Give me the number of seconds I should sleep..."
            )

        args = shlex.split(self.command_line)

        self.add_arg("duration", args[0], ParameterType.Number)


class ShellCommand(CommandBase):
    cmd = "sleep"
    needs_admin = False
    help_cmd = "sleep {duration}"
    description = "Request the agent sleep for a number of seconds"
    version = 1
    author = "@ArchiMoebius"
    attackmapping = []
    argument_class = SleepArguments
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Linux, SupportedOS.Windows],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = f'Sleeping for {task.args.get_arg("duration")} seconds!'
        return task

    async def process_response(self, response: AgentResponse):
        pass
