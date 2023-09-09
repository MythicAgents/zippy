from mythic_container.MythicCommandBase import *


class RansomArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        if len(self.command_line) > 0:
            raise Exception("Ransom command takes no parameters.")


class RansomCommand(CommandBase):
    cmd = "ransom"
    needs_admin = False
    help_cmd = "ransom"
    description = "Task the implant to show the Ransom screen"
    version = 1
    is_file_browse = False
    is_process_list = False
    is_download_file = False
    is_upload_file = False
    is_remove_file = False
    author = "@ArchiMoebius"
    argument_class = RansomArguments
    attackmapping = []

    async def create_tasking(self, task: MythicTask) -> MythicTask:
        return task

    async def process_response(self, response: AgentResponse):
        pass
