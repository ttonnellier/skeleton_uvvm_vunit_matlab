# Skeleton VUnit-UVVM-Matlab

## Introduction
This is a simple skeleton for automatic testbenches.  
Data generation is done using a matlab script.  
Two testbenches are provided: one that only uses Vunit, another that also uses UVVM.  


## Installation
3 tools are required:
* matlab
* a VHDL simulator (modelsim is assumed in the following)
* VUnit
* UVVM

### Modelsim
If you don't already have it, simply install the [Intel FPGA Starter Edition](https://fpgasoftware.intel.com/?product=modelsim_ae#tabs-2)

### VUnit installation
Just follow [these instructions](https://vunit.github.io/installing.html#using-the-python-package-manager).


### UVVM installation
In the folder where you want to install UVVM, proceed to the following:
``` bash
git clone https://github.com/UVVM/UVVM
cd script
vsim -c -do "compile_all.do"
```

### Update the paths
After cloning this repo and installing the required tools:
```
1. Open the file sim/modelsim.ini
2. Find the section UVVM librairies
3. Update the different paths to reflect your installation and close the file
``` 

## Run 
```
python run.py
```
or, if you already generated the data and don't want to relaunch matlab, because it's a stupidly heavy tool:
```
python run.py --no_data_gen
```
For VUnit CLI options, please have a look [there](https://vunit.github.io/cli.html).