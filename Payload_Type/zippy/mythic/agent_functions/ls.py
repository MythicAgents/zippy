from mythic_payloadtype_container.MythicCommandBase import *
from mythic_payloadtype_container.MythicRPC import *

import json


class LsArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)

        self.args = [
            CommandParameter(
                name="path",
                type=ParameterType.String,
                parameter_group_info=[ParameterGroupInfo(required=False)],
                description="Path of file or folder on the current system to list",
            )
        ]

    async def parse_arguments(self):

        if len(self.command_line) > 0:
            if self.command_line[0] == "{":
                temp_json = json.loads(self.command_line)

                if "host" in temp_json:
                    self.add_arg("path", temp_json["path"] + "/" + temp_json["file"])
                    self.add_arg("file_browser", True, type=ParameterType.Boolean)
                else:
                    self.add_arg("path", temp_json["path"])
            else:
                self.add_arg("path", self.command_line)
        else:
            self.add_arg("path", ".")


class LsCommand(CommandBase):
    cmd = "ls"
    needs_admin = False
    help_cmd = "ls [/path/to/folder/or/file]"
    description = "Get a file listing"
    version = 1
    author = "@ArchiMoebius"
    attackmapping = ["T1083"]
    supported_ui_features = ["file_browser:list"]
    is_file_browse = True
    argument_class = LsArguments
    browser_script = []
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_tasking(self, task: MythicTask) -> MythicTask:

        if task.args.has_arg("file_browser") and task.args.get_arg("file_browser"):
            task.display_params = f'{task.callback.host}:{task.args.get_arg("path")}'
        else:
            task.display_params = task.args.get_arg("path")

        return task

    async def process_response(self, response: AgentResponse):
        pass
