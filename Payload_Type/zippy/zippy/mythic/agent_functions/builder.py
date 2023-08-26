import asyncio
import os
import shutil
import tempfile

from distutils.dir_util import copy_tree

from mythic_container.PayloadBuilder import *
from mythic_container.MythicCommandBase import *
from mythic_container.MythicRPC import *

class Zippy(PayloadType):
    name = "zippy"
    file_extension = "exe"
    author = "@ArchiMoebius"
    supported_os = [
        SupportedOS.Windows,
        SupportedOS.Linux,
    ]
    version = "4.0.0"
    wrapper = False
    wrapped_payloads = []
    note = """Currently - only Linux support - and not on a headless display - requires opengl!"""
    supports_dynamic_loading = False  # setting this to True allows users to only select a subset of commands when generating a payload
    build_parameters = {
        BuildParameter(
            name="arch",
            parameter_type=BuildParameterType.ChooseOne,
            choices=["x64", "x86"],
            default_value="x64",
            description="Target architecture",
        ),
        BuildParameter(
            name="debug",
            parameter_type=BuildParameterType.Boolean,
            default_value=False,
            description="Build an agent with debug turned on",
        ),
        BuildParameter(
            name="tls_verify",
            parameter_type=BuildParameterType.Boolean,
            default_value=False,
            description="Enable TLS certificate verification",
        ),
    }
    c2_profiles = ["websocket"]
    agent_path = pathlib.Path(".") / "zippy" / "mythic"
    agent_code_path = pathlib.Path(".") / "zippy" / "agent_code"
    agent_icon_path = agent_path / "agent_functions" / "zippy.svg"
    
    build_steps = [
        BuildStep(step_name="Gathering Files", step_description="Copying files to temp location"),
        BuildStep(step_name="Compiling", step_description="Compiling with nuget and msbuild"),
        BuildStep(step_name="Praise", step_description="Praise Thah...it finished!"),
    ]

    async def build(self) -> BuildResponse:
        resp = BuildResponse(
            status=BuildStatus.Success, build_stdout=f"{self.selected_os}"
        )

        build_msg = ""
        debug = ""

        try:
            with tempfile.TemporaryDirectory(suffix=self.uuid) as agent_build_path:
                copy_tree(self.agent_code_path, agent_build_path)

                for c2 in self.c2info:

                    try:
                        profile = c2.get_c2profile()

                        with open(
                            f"{agent_build_path}/config_{profile.get('name', '')}.json",
                            "w",
                        ) as fh:
                            c2_config = c2.get_parameters_dict()

                            c2_config["payload_uuid"] = self.uuid
                            c2_config["tls_verify"] = self.get_parameter("tls_verify")

                            build_msg += json.dumps(c2_config, indent=2)

                            fh.write(json.dumps(c2_config, indent=2))
                            fh.flush()
                    except Exception as p:
                        build_msg += str(p)

                outputType = self.get_parameter("arch").lower()
                debug = self.get_parameter("debug")
                defaultOutputType = "x86"

                if outputType != defaultOutputType:
                    outputType = f"{defaultOutputType}_{outputType.replace('x', '')}"

                await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                    PayloadUUID=self.uuid,
                    StepName="Gathering Files",
                    StepStdout="Found all files for payload",
                    StepSuccess=True
                ))

                debug = "--debug" if debug else ""

                command = f"godot {debug} --quiet --export Zippy_{self.selected_os}_{outputType}"  # i.e. Linux_x86_64

                proc = await asyncio.create_subprocess_shell(
                    command,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE,
                    cwd=str(agent_build_path),
                )
                stdout, stderr = await proc.communicate()

                if stdout:
                    build_msg += f"[stdout]\n{stdout.decode()}\n"

                if stderr:
                    build_msg += f"[stderr]\n{stderr.decode()}" + "\n" + command

                built_file_extension = 'exe' if self.selected_os.lower() == 'windows' else 'elf'

                with open(
                    f"{agent_build_path}/build/zippy_{self.selected_os.lower()}_{outputType}.{built_file_extension}",
                    "rb",
                ) as fh:
                    resp.payload = fh.read()
                    build_msg += f"Built: {agent_build_path}"
                await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                    PayloadUUID=self.uuid,
                    StepName="Compiling",
                    StepStdout=f"Successfully built!\n{agent_build_path}",
                    StepSuccess=True
                ))
                resp.status = BuildStatus.Success
        except Exception as e:
            await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                PayloadUUID=self.uuid,
                StepName="Compiling",
                StepStdout=stdout_err,
                StepSuccess=False
            ))
            resp.status = BuildStatus.Error
            resp.payload = b""
            resp.build_message = f"Unknown error while building payload. Check the stderr for this build. {e}"
            resp.build_stderr = stdout_err
        finally:
            await SendMythicRPCPayloadUpdatebuildStep(MythicRPCPayloadUpdateBuildStepMessage(
                PayloadUUID=self.uuid,
                StepName="Praise",
                StepStdout="Ah ha - we're done...did it work?",
                StepSuccess=True
            ))

        return resp
