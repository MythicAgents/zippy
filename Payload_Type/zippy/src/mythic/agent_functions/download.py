import json
import shlex

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *


class DownloadArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = []

    async def parse_arguments(self):
        if len(self.command_line.strip()) == 0:
            raise Exception(
                "command requires a path to a file for download from agent machine.\n\tUsage: {}".format(
                    DownloadCommand.help_cmd
                )
            )

        filename = ""

        if self.command_line[0] == "{":
            temp_json = json.loads(self.command_line)
            filename = temp_json["path"] + "/" + temp_json["file"]
        else:

            args = shlex.split(self.command_line)

            self.add_arg(
                "file_path", args[0], ParameterType.String
            )  # TODO: support multiple files at once? pass files, args?...

        if filename != "":
            self.add_arg("file_path", filename, ParameterType.String)


class DownloadCommand(CommandBase):
    cmd = "download"
    needs_admin = False
    help_cmd = "download /etc/passwd"
    description = "Download a file from the victim machine - parsed as POSIX paths"
    version = 1
    supported_ui_features = ["file_browser:download"]
    is_download_file = True
    author = "@ArchiMoebius"
    parameters = []
    attackmapping = ["T1020", "T1030", "T1041"]
    argument_class = DownloadArguments
    browser_script = None
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_go_tasking(self, taskData: PTTaskMessageAllData) -> PTTaskCreateTaskingMessageResponse:
        response = PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=True,
        )
        response.DisplayParams = taskData.args.get_arg("file_path")

        return response

    async def process_response(self, task: PTTaskMessageAllData, response: any) -> PTTaskProcessResponseMessageResponse:
        resp = PTTaskProcessResponseMessageResponse(TaskID=task.Task.ID, Success=True)

        return resp