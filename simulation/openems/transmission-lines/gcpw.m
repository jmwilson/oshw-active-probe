close all
clear
clc

physical_constants;

%% Set GCPW parameters here
unit = 25.4e-6; % mil
f_min = 1e9;
f_max = 3e9;

dump_fields = false;
substrate_thickness = 8;
substrate_er = 3.66;

MSL_length = 1000;
MSL_width = 13.5;
MSL_thickness = 1.7;
if MSL_thickness < substrate_thickness/10
	MSL_thickness = 0;
end

cpwg_gap = 10;
via_spacing = 50;
via_dia = 10;
min_annular_ring = 4;
via_distance = MSL_width + 2*cpwg_gap + via_dia + 2*min_annular_ring;
board_width = 3*via_distance;

% Setup FDTD
f0 = (f_min + f_max)/2;
fc = f_max - f0;
FDTD = InitFDTD();
FDTD = SetGaussExcite(FDTD, f0, fc);
BC   = {'PML_8' 'PML_8' 'PEC' 'PEC' 'PEC' 'MUR'};
FDTD = SetBoundaryCond(FDTD, BC);

% Setup geometry
CSX = InitCSX();
resolution = C0/(f_max*sqrt(substrate_er))/unit/200; % resolution of lambda/50
mesh.x = SmoothMeshLines([-MSL_length, -MSL_length/3, MSL_length/3, MSL_length, -MSL_length:via_spacing:MSL_length], resolution, 1.5);
if MSL_thickness == 0
	mesh.y = SmoothMeshLines([0, MSL_width/2 + [-resolution/3, 2*resolution/3]/4, MSL_width/2+cpwg_gap-[-resolution/3, 2*resolution/3]/4], resolution/4 , 1.5);
else
	mesh.y = SmoothMeshLines([0, MSL_width/2, MSL_width/2+cpwg_gap], resolution/4 , 1.5);
end
mesh.y = RecursiveSmoothMesh([-board_width, -via_distance/2, -mesh.y, mesh.y, via_distance/2, board_width], resolution, 1.5);
mesh.z = RecursiveSmoothMesh([linspace(0,substrate_thickness,5), linspace(substrate_thickness, substrate_thickness + MSL_thickness, 5), 10*substrate_thickness], resolution, 1.5);
CSX = DefineRectGrid(CSX, unit, mesh);

% Substrate
CSX = AddMaterial(CSX, 'RO4350B');
CSX = SetMaterialProperty(CSX, 'RO4350B', 'Epsilon', substrate_er);
start = [mesh.x(1),   mesh.y(1),   0];
stop  = [mesh.x(end), mesh.y(end), substrate_thickness];
CSX = AddBox(CSX, 'RO4350B', 0, start, stop);

% Top ground plane
CSX = AddMetal(CSX, 'PEC');
CSX = AddMetal(CSX, 'via');
CSX = AddBox(CSX, 'PEC', 100, [mesh.x(1), mesh.y(1), substrate_thickness], [mesh.x(end), -MSL_width/2 - cpwg_gap, substrate_thickness + MSL_thickness]);
CSX = AddBox(CSX, 'PEC', 100, [mesh.x(1), mesh.y(end), substrate_thickness], [mesh.x(end), MSL_width/2 + cpwg_gap, substrate_thickness+ MSL_thickness]);
for x = -MSL_length+via_spacing/2:via_spacing:MSL_length-via_spacing/2
	CSX = AddCylinder(CSX, 'via', 100, [x, via_distance/2, 0], [x, via_distance/2, substrate_thickness], via_dia/2);
	CSX = AddCylinder(CSX, 'via', 100, [x, -via_distance/2, 0], [x, -via_distance/2, substrate_thickness], via_dia/2);
end

% MSL port
portstart = [mesh.x(1), -MSL_width/2, substrate_thickness];
portstop  = [0, MSL_width/2, 0];
[CSX,port{1}] = AddThickMetalMSLPort(CSX, 100, 1, 'PEC', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', 10*resolution, 'MeasPlaneShift',  MSL_length/3, 'Thickness', MSL_thickness);

portstart = [mesh.x(end), -MSL_width/2, substrate_thickness];
portstop  = [0, MSL_width/2, 0];
[CSX,port{2}] = AddThickMetalMSLPort(CSX, 100, 2, 'PEC', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  MSL_length/3, 'Thickness', MSL_thickness);

% Optional: dump box
if dump_fields
	CSX = AddDump(CSX, 'Ef', 'DumpType', 10, 'Frequency', [f0]);
	CSX = AddDump(CSX, 'Hf', 'DumpType', 11, 'Frequency', [f0]);
	CSX = AddBox(CSX, 'Ef', 10, [min(mesh.x), min(mesh.y), min(mesh.z)], [max(mesh.x), max(mesh.y), max(mesh.z)]);
	CSX = AddBox(CSX, 'Hf', 10, [min(mesh.x), min(mesh.y), min(mesh.z)], [max(mesh.x), max(mesh.y), max(mesh.z)]);
end

% Run simluation
Sim_Path = 'run';
Sim_CSX = 'csx.xml';

status = rmdir(Sim_Path, 's');
status = mkdir(Sim_Path);

WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);
CSXGeomPlot([Sim_Path '/' Sim_CSX]);
RunOpenEMS(Sim_Path, Sim_CSX);

% Post-processing and plots
close all
f = linspace(f0-fc, f0+fc, 2001);
port = calcPort(port, Sim_Path, f, 'RefImpedance', 50);

s11 = port{1}.uf.ref ./ port{1}.uf.inc;
s21 = port{2}.uf.ref ./ port{1}.uf.inc;

subplot(211);
hold on;
grid on;
plot(f/1e9,20*log10(abs(s11)),'k-','LineWidth',2);
plot(f/1e9,20*log10(abs(s21)),'r--','LineWidth',2);
ylim("auto");
ylabel('S-Parameter (dB)','FontSize',12);
xlabel('frequency (GHz)','FontSize',12);
legend('S_{11}','S_{21}');
subplot(212);
plot(f/1e9,abs((1+s11)./(1-s11)*50),'LineWidth',2);
xlabel('frequency (GHz)','FontSize',12);
ylabel('impedance (Ω)','FontSize',12);
waitfor(gcf);
