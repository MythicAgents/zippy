import json
import shlex
import argparse

from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *

CURL_HTTP_METHOD = ["GET", "POST", "HEAD", "PUT", "DELETE"]

CURL_ARGPARSE = argparse.ArgumentParser("curl")
CURL_ARGPARSE.add_argument(
    "-X",
    "--method",
    action="store",
    default="GET",
    choices=CURL_HTTP_METHOD,
    help="If present, defines the HTTP method to invoke - default is GET",
)
CURL_ARGPARSE.add_argument(
    "-H",
    action="append",
    default=[],
    help="If present, contains additional headers to send",
)
CURL_ARGPARSE.add_argument(
    "-d",
    "--data",
    default="",
    action="store",
    help="If present, the content must be base64 encoded",
)
CURL_ARGPARSE.add_argument(
    "url",
    nargs="+",
    help="The last argument is positional - the URL",
)


class CurlArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="method",
                choices=CURL_HTTP_METHOD,
                parameter_group_info=[
                    ParameterGroupInfo(required=False, ui_position=1)
                ],
                type=ParameterType.ChooseOne,
                description="The HTTP request method invoked",
            ),
            CommandParameter(
                name="headers",
                parameter_group_info=[
                    ParameterGroupInfo(required=False, ui_position=2)
                ],
                type=ParameterType.Array,
                description="Extra headers to apply",
            ),
            CommandParameter(
                name="body",
                parameter_group_info=[
                    ParameterGroupInfo(
                        required=False,
                        ui_position=3,
                    )
                ],
                type=ParameterType.String,
                description="Path of file or folder on the current system to list",
            ),
            CommandParameter(
                name="url",
                parameter_group_info=[
                    ParameterGroupInfo(
                        required=True,
                        ui_position=4,
                    )
                ],
                type=ParameterType.String,
                description="The http/https resource to interact with",
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line.strip()) == 0:
            raise Exception("Usage: {}".format(CurlCommand.help_cmd))

        try:
            args = CURL_ARGPARSE.parse_args(shlex.split(self.command_line))

            self.add_arg("url", args.url, ParameterType.String)
            self.add_arg("method", args.method, ParameterType.String)
            self.add_arg("body", args.data, ParameterType.String)
            self.add_arg("headers", args.H, ParameterType.Array)
        except SystemExit:
            raise Exception("Usage: {}".format(CurlCommand.help_cmd))


class CurlCommand(CommandBase):
    cmd = "curl"
    needs_admin = False
    help_cmd = "curl --data 'base64EncodedBlob' -H 'some extra header' -X POST --url https://canhazip.com/"
    description = "Invoke a HTTP(S) Client and point it at a URL"
    version = 1
    supported_ui_features = ["file_browser:download"]
    is_download_file = True
    author = "@ArchiMoebius"
    parameters = []
    attackmapping = ["T1020", "T1030", "T1041"]
    argument_class = CurlArguments
    browser_script = None
    attributes = CommandAttributes(
        supported_os=[SupportedOS.MacOS, SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_go_tasking(
        self, taskData: PTTaskMessageAllData
    ) -> PTTaskCreateTaskingMessageResponse:
        response = PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=True,
        )
        response.DisplayParams = taskData.args.get_arg("url")

        return response

    async def process_response(
        self, task: PTTaskMessageAllData, response: any
    ) -> PTTaskProcessResponseMessageResponse:
        resp = PTTaskProcessResponseMessageResponse(TaskID=task.Task.ID, Success=True)

        return resp
