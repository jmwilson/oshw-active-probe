close all
clear
clc

physical_constants;

%% Set GCPW parameters here
unit = 25.4e-6; % mil
f_min = 1e9;
f_max = 9e9;

dump_fields = false;
substrate_thickness = 8;
substrate_er = 3.68;

MSL_length = 1500;
MSL_width = 13.5;
MSL_thickness = 1.7;

cpwg_gap = 10;
via_spacing = 50;
via_dia = 10;
min_annular_ring = 4;
board_width = 700/2;
via_distance = MSL_width + 2*cpwg_gap + via_dia + 2*min_annular_ring;

if MSL_thickness < substrate_thickness/10 && MSL_thickness < cpwg_gap/10
	MSL_thickness = 0;
end

%% Setup FDTD
f0 = (f_min + f_max)/2;
fc = f_max - f0;
FDTD = InitFDTD();
FDTD = SetGaussExcite(FDTD, f0, fc);
BC   = {'PML_8' 'PML_8' 'MUR' 'MUR' 'PEC' 'MUR'};
FDTD = SetBoundaryCond(FDTD, BC);

%% Setup geometry
CSX = InitCSX();
resolution = C0/(f_max*sqrt(substrate_er))/unit/40; % resolution of lambda/40
mesh.y = [linspace(0, MSL_width/2, 4), linspace(MSL_width/2, MSL_width/2+cpwg_gap, 8)];
mesh.x = SmoothMeshLines([-MSL_length, -MSL_length/3, MSL_length/3, MSL_length, -MSL_length+via_spacing/2:via_spacing:MSL_length-via_spacing/2], resolution, 1.5);
mesh.y = RecursiveSmoothMesh([-board_width, -via_distance/2, -mesh.y, mesh.y, via_distance/2, board_width], resolution, 1.4);
mesh.z = SmoothMeshLines2([linspace(0,substrate_thickness,5), linspace(substrate_thickness, substrate_thickness + MSL_thickness, 5), 10*substrate_thickness], resolution, 1.5);
CSX = DefineRectGrid(CSX, unit, mesh);

% Substrate
CSX = AddDebyeMaterial(CSX, 'FR408HR');
f = [f_min f_max];
tau = 1./(2*pi*f);
[eps_delta, eps_inf] = simplified_debye_fit(substrate_er, 0.0092, 2.3e-12, f); % datasheet values for FR408HR
CSX = SetMaterialProperty(CSX, 'FR408HR', 'Epsilon', eps_inf, 'EpsilonDelta_1', eps_delta(1), 'EpsilonDelta_2', eps_delta(2), 'EpsilonRelaxTime_1', tau(1), 'EpsilonRelaxTime_2', tau(2));
start = [mesh.x(1),   mesh.y(1),   0];
stop  = [mesh.x(end), mesh.y(end), substrate_thickness];
CSX = AddBox(CSX, 'FR408HR', 0, start, stop);

% Top ground plane
CSX = AddMetal(CSX, 'PEC');
CSX = AddMetal(CSX, 'via');
CSX = AddBox(CSX, 'PEC', 100, [mesh.x(1), mesh.y(1), substrate_thickness], [mesh.x(end), -MSL_width/2 - cpwg_gap, substrate_thickness + MSL_thickness]);
CSX = AddBox(CSX, 'PEC', 100, [mesh.x(1), mesh.y(end), substrate_thickness], [mesh.x(end), MSL_width/2 + cpwg_gap, substrate_thickness + MSL_thickness]);
for x = -MSL_length+via_spacing/2:via_spacing:MSL_length-via_spacing/2
	CSX = AddCylinder(CSX, 'via', 100, [x, via_distance/2, 0], [x, via_distance/2, substrate_thickness], via_dia/2);
	CSX = AddCylinder(CSX, 'via', 100, [x, -via_distance/2, 0], [x, -via_distance/2, substrate_thickness], via_dia/2);
end

% MSL port
portstart = [mesh.x(1), -MSL_width/2, substrate_thickness];
portstop  = [0, MSL_width/2, 0];
if MSL_thickness == 0
	[CSX,port{1}] = AddMSLPort(CSX, 100, 1, 'PEC', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', mesh.x(10) - mesh.x(1), 'MeasPlaneShift',  MSL_length/3);
else
	[CSX,port{1}] = AddThickMetalMSLPort(CSX, 100, 1, 'PEC', portstart, portstop, 0, [0 0 -1], 'ExcitePort', true, 'FeedShift', mesh.x(10) - mesh.x(1), 'MeasPlaneShift',  MSL_length/3, 'Thickness', MSL_thickness);
end

portstart = [mesh.x(end), -MSL_width/2, substrate_thickness];
portstop  = [0, MSL_width/2, 0];
if MSL_thickness == 0
	[CSX,port{2}] = AddMSLPort(CSX, 100, 2, 'PEC', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  MSL_length/3);
else
	[CSX,port{2}] = AddThickMetalMSLPort(CSX, 100, 2, 'PEC', portstart, portstop, 0, [0 0 -1], 'MeasPlaneShift',  MSL_length/3, 'Thickness', MSL_thickness);
end

% Optional: dump box
if dump_fields
	CSX = AddDump(CSX, 'Ef', 'DumpType', 10, 'Frequency', [f0]);
	CSX = AddDump(CSX, 'Hf', 'DumpType', 11, 'Frequency', [f0]);
	CSX = AddBox(CSX, 'Ef', 10, [min(mesh.x), min(mesh.y), min(mesh.z)], [max(mesh.x), max(mesh.y), max(mesh.z)]);
	CSX = AddBox(CSX, 'Hf', 10, [min(mesh.x), min(mesh.y), min(mesh.z)], [max(mesh.x), max(mesh.y), max(mesh.z)]);
end

%% Run simluation
Sim_Path = 'run';
Sim_CSX = 'csx.xml';

status = rmdir(Sim_Path, 's');
status = mkdir(Sim_Path);

WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);
CSXGeomPlot([Sim_Path '/' Sim_CSX]);
RunOpenEMS(Sim_Path, Sim_CSX);

%% Post-processing and plots
close all
f = linspace(f0-fc, f0+fc, 2001);
port = calcPort(port, Sim_Path, f, 'RefImpedance', 50);

s11 = port{1}.uf.ref ./ port{1}.uf.inc;
s21 = port{2}.uf.ref ./ port{1}.uf.inc;

if exist('OCTAVE_VERSION') ~= 0
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
else
	sparamdata(1,1,:) = s11;
	sparamdata(1,2,:) = s21;
	sparamdata(2,1,:) = s21;
	sparamdata(2,2,:) = s11;
	sobj = sparameters(sparamdata, f);
	rfwrite(sobj, [Sim_Path '/' 'line.s2p']);
	rfplot(sobj, {[1 1] [2 1]});
end
