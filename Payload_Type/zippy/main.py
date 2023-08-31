import shlex
import subprocess
import sys
from pathlib import PosixPath

import mythic_container
from src.c2_code.profile import *
from src.mythic import *

mythic_container.mythic_service.start_and_run_forever()