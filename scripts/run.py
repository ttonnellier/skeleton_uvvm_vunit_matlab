import os
import subprocess

from collections import namedtuple

from pathlib import Path

import sys
sys.path.append("C:/Users/s15073/Documents/Airbus/Code/Refresher/vunit")

from vunit import VUnit
from vunit import VUnitCLI, VUnit


HDL_PATH = Path(__file__).resolve().parent.parent / "hdl"
PKG_PATH = Path(__file__).resolve().parent.parent / "pkg"
TST_PATH = Path(__file__).resolve().parent.parent / "tb"
DAT_PATH = Path(__file__).resolve().parent.parent / "data"

AWIDTH  = 8
BWIDTH  = 8
CWIDTH  = 17
SAMPLES = 10

os.environ["VUNIT_MODELSIM_INI"] = "modelsim.ini"

# Add custom command line argument to standard CLI
# Beware of conflicts with existing arguments
cli = VUnitCLI()
cli.parser.add_argument('--no_data_gen', action='store_true')
args = cli.parse_args()
VU = VUnit.from_args(args=args)

# Create libraries and load files
DL = VU.add_library("design_library")
DL.add_source_files(HDL_PATH / "*.vhd")
PL = VU.add_library("package_library")
PL.add_source_files(PKG_PATH / "*.vhd")
TL = VU.add_library("test_library")
TL.add_source_files(TST_PATH / "*.vhd")


# Generate data set via Matlab
if args.no_data_gen:
    print ("## No data generation requested by user")
else:
    Matlab_Params = namedtuple('Matlab_Params', 'path awidth bwidth cwidth samples')
    matlab_params = Matlab_Params(DAT_PATH.absolute(), AWIDTH, BWIDTH, CWIDTH, SAMPLES)
    print("## Generating data via Matlab")
    proc =  subprocess.Popen("matlab -batch \"cd(\'{params.path}\'); generate_data_preAddMultAdd({params.awidth},{params.bwidth},{params.cwidth},{params.samples}); exit\"".format(params=matlab_params))
    exit_code = proc.wait()
    if exit_code == 0:
        print("#### Data generated")
    else:
        print("#### Error in data generation... Exiting...")
        exit()

# Set Modelsim options
VU.set_sim_option("modelsim.vsim_flags", ["-stats=-cmd,-time"])

# Fill TB's generics
# TB_preAddMultAdd = TL.test_bench("preAddMultAdd_uvvm_tb")
TB_preAddMultAdd = TL.test_bench("preAddMultAdd_vunit_tb")
TB_preAddMultAdd.set_generic("DATA_PATH", DAT_PATH.absolute().as_posix() + "/")
TB_preAddMultAdd.set_generic("FILE_IN" , "preAddMultAdd_matlab_in.txt")
TB_preAddMultAdd.set_generic("FILE_OUT", "preAddMultAdd_matlab_out.txt")
TB_preAddMultAdd.set_generic("AWIDTH", AWIDTH)
TB_preAddMultAdd.set_generic("BWIDTH", BWIDTH)
TB_preAddMultAdd.set_generic("CWIDTH", CWIDTH)

# TB_preAddMultAdd.set_generic("DATA_PATH", DAT_PATH.absolute().as_posix() + "/")
# TB_preAddMultAdd.set_generic("FILE_IN" , "preAddMultAdd_in.txt")
# TB_preAddMultAdd.set_generic("FILE_OUT", "preAddMultAdd_out.txt")
# TB_preAddMultAdd.set_generic("AWIDTH", 8)
# TB_preAddMultAdd.set_generic("BWIDTH", 8)
# TB_preAddMultAdd.set_generic("CWIDTH", 8)

VU.main()