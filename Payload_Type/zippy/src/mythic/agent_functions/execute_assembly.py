from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *

from sys import exc_info


class ExecuteAssemblyArguments(TaskArguments):
    def __init__(self, command_line, **kwargs):
        super().__init__(command_line, **kwargs)
        self.args = [
            CommandParameter(
                name="binary",
                type=ParameterType.File,
                description="file to upload",
            ),
            CommandParameter(
                name="arguments",
                type=ParameterType.String,
                description="Arguments to pass when invoking the provided binary executable",
            ),
        ]

    async def parse_arguments(self):
        if len(self.command_line) == 0:
            raise ValueError("Must supply arguments")
        raise ValueError("Must supply named arguments or use the modal")

    async def parse_dictionary(self, dictionary_arguments):
        self.load_args_from_dictionary(dictionary_arguments)


class ExecuteAssemblyCommand(CommandBase):
    cmd = "execute_assembly"
    needs_admin = False
    help_cmd = "execute_assembly <assembly to upload and execute> <arguments>"
    description = (
        "Upload a file to the target machine by selecting a file from your computer. "
    )
    version = 1
    supported_ui_features = ["file_browser:upload"]
    author = "@ArchiMoebius"
    attackmapping = ["T1132", "T1030", "T1105"]
    argument_class = ExecuteAssemblyArguments
    attributes = CommandAttributes(
        supported_os=[SupportedOS.Windows, SupportedOS.Linux],
    )

    async def create_go_tasking(
        self, taskData: MythicCommandBase.PTTaskMessageAllData
    ) -> MythicCommandBase.PTTaskCreateTaskingMessageResponse:
        response = MythicCommandBase.PTTaskCreateTaskingMessageResponse(
            TaskID=taskData.Task.ID,
            Success=True,
        )
        try:
            file_resp = await SendMythicRPCFileSearch(
                MythicRPCFileSearchMessage(
                    TaskID=taskData.Task.ID, AgentFileID=taskData.args.get_arg("binary")
                )
            )
            if file_resp.Success:
                if len(file_resp.Files) > 0:
                    original_file_name = file_resp.Files[0].Filename
                    response.DisplayParams = f" running {original_file_name} {taskData.args.get_arg('arguments')}"
                else:
                    raise Exception("Failed to find that file")
            else:
                raise Exception(
                    "Error from Mythic trying to get file: " + str(file_resp.Error)
                )
        except Exception as e:
            raise Exception(
                "Error from Mythic: "
                + str(sys.exc_info()[-1].tb_lineno)
                + " : "
                + str(e)
            )
        return response

    async def process_response(
        self, task: PTTaskMessageAllData, response: any
    ) -> PTTaskProcessResponseMessageResponse:
        resp = PTTaskProcessResponseMessageResponse(TaskID=task.Task.ID, Success=True)
        return resp
