function [CSX, port] = prepare_pcb(CSX, excite_port)

layer_names = {'Top', 'Ground', 'Signal/Power', 'Bottom'};
components = {
	% Resistors
	struct('name', 'R1',  'orientation', 'x', 'value', 220),
	struct('name', 'R2',  'orientation', 'x', 'value', 1.6e6),
	struct('name', 'R3',  'orientation', 'y', 'value', 402e3),
	struct('name', 'R4',  'orientation', 'y', 'value', 1.91e6),
	struct('name', 'R6',  'orientation', 'y', 'value', 66.5e3),
	struct('name', 'R10', 'orientation', 'x', 'value', 10e6),
	struct('name', 'R11', 'orientation', 'y', 'value', 68)
	% Capacitors
	struct('name', 'C8', 'orientation', 'y', 'value', 2.2e-12),
	struct('name', 'C6', 'orientation', 'x', 'value', 800e-15),
	struct('name', 'C1', 'orientation', 'x', 'value', 330e-12)
};
physical_constants;
lambda = c0/sqrt(3.61)/3e9;
fine_resolution = lambda/200;
coarse_resolution = lambda/40;
grid_duplicate_threshold = 5e-5;
air_space = 5e-3;

% Get grid
mesh.x = CSX.RectilinearGrid.XLines;
mesh.y = CSX.RectilinearGrid.YLines;
mesh.z = CSX.RectilinearGrid.ZLines;

mesh.x(end+1) = min(mesh.x) - air_space;
mesh.x(end+1) = max(mesh.x) + air_space;
mesh.y(end+1) = min(mesh.y) - air_space;
mesh.y(end+1) = max(mesh.y) + air_space;
mesh.z(end+1) = min(mesh.z) - air_space;
mesh.z(end+1) = max(mesh.z) + air_space;

%% 1. Add via grids
type = GetPropertyType(CSX, 'via');
pos = GetPropertyPosition(CSX, type, 'via');

for n=1:numel(CSX.Properties.(type){pos}.Primitives.('Cylinder'))
	prim = CSX.Properties.(type){pos}.Primitives.('Cylinder'){n};
	mesh.x(end+1) = prim.P1.ATTRIBUTE.X;
	mesh.y(end+1) = prim.P1.ATTRIBUTE.Y;
	mesh.z(end+1) = prim.P1.ATTRIBUTE.Z;
	mesh.z(end+1) = prim.P2.ATTRIBUTE.Z;
end

%% 2. Add z levels for layer
for n=1:numel(layer_names)
	type = GetPropertyType(CSX, [layer_names{n} '_copper']);
	pos = GetPropertyPosition(CSX, type, [layer_names{n} '_copper']);
	prop_types = fieldnames(CSX.Properties.(type){pos}.Primitives);
	mesh.z(end+1) = CSX.Properties.(type){pos}.Primitives.(prop_types{1}){1}.ATTRIBUTE.Elevation;
	layer_height.(layer_names{n}) = CSX.Properties.(type){pos}.Primitives.(prop_types{1}){1}.ATTRIBUTE.Elevation;
end

%% 3. Add components
for n=1:numel(components)
	[pad1_material, pad1_start, pad1_stop] = GetHyperLynxPort(CSX, [components{n}.name '.1']);
	[pad2_material, pad2_start, pad2_stop] = GetHyperLynxPort(CSX, [components{n}.name '.2']);
	if (strcmp(components{n}.name(1), 'R'))
		CSX = AddLumpedElement(CSX, [components{n}.name '-' components{n}.orientation '-' num2str(components{n}.value)], components{n}.orientation, 'Caps', 1, 'R', components{n}.value);
	elseif (strcmp(components{n}.name(1), 'C'))
		CSX = AddLumpedElement(CSX, [components{n}.name '-' components{n}.orientation '-' num2str(components{n}.value)], components{n}.orientation, 'Caps', 1, 'C', components{n}.value);
	else
		error(['prepare_pcb: unknown lumped element type for component ' components{n}.name]);
	end
	if (strcmp(components{n}.orientation, 'x'))
		component_start = [(pad1_start(1) + pad1_stop(1))/2;pad1_start(2);pad1_start(3)];
		component_stop = [(pad2_start(1) + pad2_stop(1))/2;pad2_stop(2);pad1_start(3) + .0005];
	else
		component_start = [pad1_start(1);(pad1_start(2) + pad1_stop(2))/2;pad1_start(3)];
		component_stop = [pad2_stop(1);(pad2_start(2) + pad2_stop(2))/2;pad1_start(3) + .0005];
	end
	CSX = AddBox(CSX, [components{n}.name '-' components{n}.orientation '-' num2str(components{n}.value)], 300, component_start, component_stop);
	mesh = AddComponentMeshLines(mesh, component_start, component_stop);
end

%% 4. Add probe tips
CSX = AddMetal(CSX, 'metal');
[pad1_material, pad1_start, pad1_stop] = GetHyperLynxPort(CSX, 'J1.1');
tip_x_start = pad1_start(1) - 3e-3;
component_start = [tip_x_start, (pad1_start(2) + pad1_stop(2))/2 - 700e-6, pad1_start(3)];
component_stop = [pad1_stop(1) - 500e-6, (pad1_start(2) + pad1_stop(2))/2 + 700e-6, pad1_start(3) + 1.4e-3];
tip_port_start = [tip_x_start, component_start(2), component_start(3)];
CSX = AddBox(CSX, 'metal', 300, component_start, component_stop);
mesh = AddComponentMeshLines(mesh, component_start, component_stop);

[pad1_material, pad1_start, pad1_stop] = GetHyperLynxPort(CSX, 'J2.1');
component_start = [tip_x_start, (pad1_start(2) + pad1_stop(2))/2 - 700e-6, pad1_start(3)];
component_stop = [pad1_stop(1) - 500e-6, (pad1_start(2) + pad1_stop(2))/2 + 700e-6, pad1_start(3) + 1.4e-3];
tip_port_stop = [tip_x_start, component_stop(2), component_stop(3)];
CSX = AddBox(CSX, 'metal', 300, component_start, component_stop);
mesh = AddComponentMeshLines(mesh, component_start, component_stop);

%% 5. Add ports
% Port 1 is the tip
[CSX, port{1}] = AddLumpedPort(CSX, 999, 1, 50, tip_port_start, tip_port_stop, [0 -1 0], 1 == excite_port);
mesh = AddComponentMeshLines(mesh, tip_port_start, tip_port_stop);
mesh.y(end+1) = .5*(tip_port_start + tip_port_stop)(2);
mesh.z(end+1) = .5*(tip_port_start + tip_port_stop)(3);
% Port 2 is BUF802 input
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U1.2');
[gnd_material, gnd_start, gnd_stop] = GetHyperLynxPort(CSX, 'U1.17');
port_2_start = [pad_stop(1), pad_start(2), pad_start(3)];
port_2_stop = [gnd_start(1) + 32e-6, pad_stop(2), pad_stop(3)];
[CSX, port{2}] = AddLumpedPort(CSX, 999, 2, 50, port_2_start, port_2_stop, [1 0 0], 2 == excite_port);
mesh = AddComponentMeshLines(mesh, port_2_start, port_2_stop);
mesh.x(end+1) = .5*(port_2_start + port_2_stop)(1);
% Port 3 is BUF802 input bias
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U1.3');
port_3_start = [pad_stop(1), pad_start(2), pad_start(3)];
port_3_stop = [gnd_start(1) + 32e-6, pad_stop(2), pad_stop(3)];
[CSX, port{3}] = AddLumpedPort(CSX, 999, 3, 50, port_3_start, port_3_stop, [1 0 0], 3 == excite_port);
mesh = AddComponentMeshLines(mesh, port_3_start, port_3_stop);
mesh.x(end+1) = .5*(port_3_start + port_3_stop)(1);
% Port 4 is op amp + input
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U2.3');
port_4_start = [(pad_start(1) + pad_stop(1))/2, pad_start(2), pad_start(3)];
port_4_stop = [(pad_start(1) + pad_stop(1))/2, pad_stop(2), layer_height.('Ground')];
[CSX, port{4}] = AddLumpedPort(CSX, 999, 4, 50, port_4_start, port_4_stop, [0 0 -1], 4 == excite_port);
mesh = AddComponentMeshLines(mesh, port_4_start, port_4_stop);
mesh.y(end+1) = .5*(port_4_start + port_4_stop)(2);
mesh.z(end+1) = .5*(port_4_start + port_4_stop)(3);

%% 6. Meshing
% Remove duplicates and nearly-coincident lines
mesh.x = sort(mesh.x);
mesh.y = sort(mesh.y);
mesh.z = sort(mesh.z);
mesh.x = mesh.x(logical([1, diff(mesh.x) >= grid_duplicate_threshold]));
mesh.y = mesh.y(logical([1, diff(mesh.y) >= grid_duplicate_threshold]));
mesh.z = mesh.z(logical([1, diff(mesh.z) >= grid_duplicate_threshold]));

% Detail box
% detail_x = [0.0075, 0.016];
% detail_y = [0.0116, 0.0194];
% mesh.x = [mesh.x, SmoothMeshLines([mesh.x(logical(detail_x(1) <= mesh.x & mesh.x <= detail_x(2))), detail_x], fine_resolution)];
% mesh.y = [mesh.y, SmoothMeshLines([mesh.y(logical(detail_y(1) <= mesh.y & mesh.y <= detail_y(2))), detail_y], fine_resolution)];

% detail_x = [0.016, 0.022];
% detail_y = [0.0082, 0.0116];
% mesh.x = [mesh.x, SmoothMeshLines([mesh.x(logical(detail_x(1) <= mesh.x & mesh.x <= detail_x(2))), detail_x], fine_resolution)];
% mesh.y = [mesh.y, SmoothMeshLines([mesh.y(logical(detail_y(1) <= mesh.y & mesh.y <= detail_y(2))), detail_y], fine_resolution)];

mesh.x = RecursiveSmoothMesh(mesh.x, coarse_resolution, 1.4);
mesh.y = RecursiveSmoothMesh(mesh.y, coarse_resolution, 1.4);
mesh.z = RecursiveSmoothMesh(mesh.z, coarse_resolution, 1.4);

CSX = DefineRectGrid(CSX, 1, mesh);

%% 7. Material fixup
% eps_FR408HR = 3.68;
% tand_FR408HR = 0.0092;
% kappa_FR408HR = 2*pi*2e9*EPS0*eps_FR408HR*tand_FR408HR;
% CSX = SetMaterialProperty(CSX, 'Dielectric_DE_Signal/Power', 'Epsilon', eps_FR408HR, 'Mue', 1, 'Kappa', kappa_FR408HR);
% CSX = SetMaterialProperty(CSX, 'Dielectric_DE_Ground', 'Epsilon', eps_FR408HR, 'Mue', 1, 'Kappa', kappa_FR408HR);
% CSX = SetMaterialProperty(CSX, 'Dielectric_DE_Top', 'Epsilon', eps_FR408HR, 'Mue', 1, 'Kappa', kappa_FR408HR);
