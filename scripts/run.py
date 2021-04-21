import os
import subprocess
from collections import namedtuple
from pathlib import Path
from vunit import VUnit
from vunit import VUnitCLI, VUnit

HDL_PATH = Path(__file__).resolve().parent.parent / "src/vhd"
TST_PATH = Path(__file__).resolve().parent.parent / "sim/tb"
DAT_PATH = Path(__file__).resolve().parent.parent / "sim/data"

# Generics used by matlab and testbench
AWIDTH  = 8
BWIDTH  = 8
CWIDTH  = 17
SAMPLES = 10

# Add custom command line argument to standard CLI
cli = VUnitCLI()
cli.parser.add_argument('--no_data_gen', action='store_true')
args = cli.parse_args()
VU = VUnit.from_args(args=args)

# Create libraries and load files
DL = VU.add_library("design_library")
DL.add_source_files(HDL_PATH / "*.vhd")
TL = VU.add_library("test_library")
TL.add_source_files(TST_PATH / "*.vhd")

# Set Modelsim options
os.environ["VUNIT_MODELSIM_INI"] = Path(__file__).resolve().parent.parent.stem + "sim/modelsim.ini"
VU.set_sim_option("modelsim.vsim_flags", ["-stats=-cmd,-time"])

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

# Fill generics with two different configurations
benches = {'TB_VU': TL.test_bench("preAddMultAdd_vunit_tb"),
           'TB_UVVM': TL.test_bench("preAddMultAdd_uvvm_tb")}

for tb in benches:
    benches[tb].set_generic("DATA_PATH", DAT_PATH.absolute().as_posix() + "/")
    benches[tb].set_generic("AWIDTH", AWIDTH)
    benches[tb].set_generic("BWIDTH", BWIDTH)
    benches[tb].set_generic("CWIDTH", CWIDTH)

for tb in benches
    benches[tb].add_config(
            name="pass",
            generics=dict(FILE_IN=preAddMultAdd_matlab_in.txt, FILE_OUT=preAddMultAdd_matlab_out.txt))
    benches[tb].add_config(
            name="fail",
            generics=dict(FILE_IN=preAddMultAdd_matlab_in_errors.txt, FILE_OUT=preAddMultAdd_matlab_out_errors.txt))

VU.main()