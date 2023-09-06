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
    file_extension = ""
    author = "@ArchiMoebius"
    supported_os = [
        SupportedOS.Linux,
        SupportedOS.Windows,
    ]
    version = "4.1.0"
    wrapper = False
    wrapped_payloads = []
    note = """No headless display support - requires opengl!"""
    supports_dynamic_loading = False  # setting this to True allows users to only select a subset of commands when generating a payload
    build_parameters = {
        BuildParameter(
            name="arch",
            parameter_type=BuildParameterType.ChooseOne,
            choices=["x86_64", "x86_32"],
            default_value="x86_64",
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
    c2_profiles = ["zippy-websocket"]
    agent_path = pathlib.Path(".") / "src" / "mythic"
    agent_code_path = pathlib.Path(".") / "src" / "agent_code"
    agent_icon_path = agent_path / "agent_functions" / "logo.svg"

    build_steps = [
        BuildStep(
            step_name="Gathering Files",
            step_description="Copying files to temp location",
        ),
        BuildStep(
            step_name="Compiling", step_description="Compiling with nuget and msbuild"
        ),
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
                            c2_config["payload_uuid"] = self.uuid
                            c2_config["tls_verify"] = self.get_parameter("tls_verify")

                            build_msg += json.dumps(c2_config, indent=2)

                            fh.write(json.dumps(c2_config, indent=2))
                            fh.flush()
                    except Exception as p:
                        build_msg += str(p)

                outputType = self.get_parameter("arch").lower()
                debug = self.get_parameter("debug")

                await SendMythicRPCPayloadUpdatebuildStep(
                    MythicRPCPayloadUpdateBuildStepMessage(
                        PayloadUUID=self.uuid,
                        StepName="Gathering Files",
                        StepStdout="Found all files for payload",
                        StepSuccess=True,
                    )
                )

                build_type = "--export-debug" if debug else "--export-release"

                command = f"godot {build_type} --verbose --headless --quiet zippy_{self.selected_os.lower()}_{outputType.lower()}"  # i.e. linux_x86_64 || linux_x86_32

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

                built_file_extension = (
                    "exe" if self.selected_os.lower() == "windows" else "elf"
                )

                with open(
                    f"{agent_build_path}/build/zippy_{self.selected_os.lower()}_{outputType}.{built_file_extension}",
                    "rb",
                ) as fh:
                    resp.payload = fh.read()
                    build_msg += f"Built: {agent_build_path}"

                await SendMythicRPCPayloadUpdatebuildStep(
                    MythicRPCPayloadUpdateBuildStepMessage(
                        PayloadUUID=self.uuid,
                        StepName="Compiling",
                        StepStdout=f"Successfully built!\n{agent_build_path}",
                        StepSuccess=True,
                    )
                )
                resp.status = BuildStatus.Success
        except Exception as e:
            await SendMythicRPCPayloadUpdatebuildStep(
                MythicRPCPayloadUpdateBuildStepMessage(
                    PayloadUUID=self.uuid,
                    StepName="Compiling",
                    StepStdout=f"Oh snap {e}\n{build_msg}",
                    StepSuccess=False,
                )
            )
            resp.status = BuildStatus.Error
            resp.payload = b""
            resp.build_message = f"Unknown error while building payload. Check the stderr for this build. {e}"
            resp.build_stderr = build_msg
        finally:
            await SendMythicRPCPayloadUpdatebuildStep(
                MythicRPCPayloadUpdateBuildStepMessage(
                    PayloadUUID=self.uuid,
                    StepName="Praise",
                    StepStdout="Ah ha - we're done...did it work?\n{build_msg}",
                    StepSuccess=True,
                )
            )

        return resp
