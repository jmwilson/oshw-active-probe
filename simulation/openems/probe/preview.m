close all
clear all
clc

f_min = 100e6;
f_max = 3e9;
f0 = (f_min + f_max)/2;
fc = f_max - f0;

FDTD = InitFDTD('EndCriteria', 1e-3);
FDTD = SetGaussExcite(FDTD, f0, fc);
BC   = {'PEC', 'PEC', 'PEC', 'PEC', 'PEC', 'PEC'};
FDTD = SetBoundaryCond(FDTD, BC);

CSX = InitCSX();
CSX = pcb(CSX);
[CSX, port] = prepare_pcb(CSX, 1);

%% Simulation files and options
Sim_Path = 'preview';
Sim_CSX = 'pcb.xml';

status = rmdir(Sim_Path, 's');
status = mkdir(Sim_Path);

openEMS_opts = '--debug-PEC --no-simulation';
WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);
CSXGeomPlot([Sim_Path '/' Sim_CSX]);
RunOpenEMS(Sim_Path, Sim_CSX, openEMS_opts);
