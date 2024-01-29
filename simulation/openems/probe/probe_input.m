close all
clear all
clc

f_min = 100e6;
f_max = 3e9;
f0 = (f_min + f_max)/2;
fc = f_max - f0;
f = logspace(log10(f0-fc), log10(f0+fc), 2001);
num_ports = 4;
sparam = cell(num_ports, num_ports);

FDTD = InitFDTD('EndCriteria', 1e-3);
FDTD = SetGaussExcite(FDTD, f0, fc);
BC   = {'PEC', 'PML_8', 'PML_8', 'PML_8', 'PML_8', 'PML_8'};
FDTD = SetBoundaryCond(FDTD, BC);

for n=1:num_ports
	CSX = InitCSX();
	CSX = pcb(CSX);
	[CSX, port] = prepare_pcb(CSX, n);

	%% Simulation files and options
	Sim_Path = ['run-port' num2str(n)];
	Sim_CSX = 'pcb.xml';

	status = rmdir(Sim_Path, 's');
	status = mkdir(Sim_Path);

	openEMS_opts = '';
	WriteOpenEMS([Sim_Path '/' Sim_CSX], FDTD, CSX);
	RunOpenEMS(Sim_Path, Sim_CSX, openEMS_opts);

	%% Post-processing

	port = calcPort(port, Sim_Path, f, 'RefImpedance', 50);
	for i=1:num_ports
		sparam{i,n} = port{i}.uf.ref ./ port{n}.uf.inc;
	end
end

fdata = f;
for i=1:num_ports
	for j=1:num_ports
		fdata(end+1,:) = real(sparam{i,j});
		fdata(end+1,:) = imag(sparam{i,j});
	end
end

fd = fopen('parameters.s4p', 'w+');
fprintf(fd, "# Hz S RI R 50\n");
fprintf(fd, "%-12g %g %g %g %g %g %g %g %g\n\
             %g %g %g %g %g %g %g %g\n\
             %g %g %g %g %g %g %g %g\n\
             %g %g %g %g %g %g %g %g\n", fdata);
fclose(fd);
