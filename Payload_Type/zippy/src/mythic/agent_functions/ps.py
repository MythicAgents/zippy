from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class PsArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        pass


class PsCommand(CommandBase):
    cmd = "ps"
    needs_admin = False
    help_cmd = "ps"
    description = "Get a process listing"
    version = 2
    author = "@ArchiMoebius"
    attackmapping = ["T1106"]
    supported_ui_features = ["process_browser:list"]
    argument_class = PsArguments
    browser_script = None
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        task.display_params = "Getting a process listing"

        return task

    async def process_response(self, response: AgentResponse):
        pass
