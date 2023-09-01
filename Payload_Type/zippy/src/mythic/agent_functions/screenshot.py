from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class ScreenshotArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="index",
                type=ParameterType.Number,
                description="The indox of the monitor to take a screenshot of",
            )
        ]

    async def parse_arguments(self):

        if len(self.command_line) > 0:
            self.add_arg("index", int(self.command_line))

    async def parse_dictionary(self, dictionary_arguments):
        self.load_args_from_dictionary(dictionary_arguments)


class ScreenshotCommand(CommandBase):
    cmd = "screenshot"
    needs_admin = False
    help_cmd = "screenshot {index}"
    description = "Attempt to retrieve a screenshot of a monitor at the specified screen index"
    version = 1
    author = "@ArchiMoebius"
    attackmapping = []
    argument_class = ScreenshotArguments
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = (
            f'of monitor: {str(task.args.get_arg("index"))}'
        )

        return task

    async def process_response(self, response: AgentResponse):
        pass
