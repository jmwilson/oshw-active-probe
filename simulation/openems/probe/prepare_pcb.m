function [CSX, port] = prepare_pcb(CSX, excite_port)

layer_names = {'Top', 'Ground', 'Signal/Power', 'Bottom'};
resistors = {
	struct('name', 'R1', 'orientation', 'x', 'value', 91, 'height', 500e-6),
	struct('name', 'R2',  'orientation', 'x', 'value', 33, 'height', 500e-6),
	struct('name', 'R3',  'orientation', 'x', 'value', 1.6e6, 'height', 500e-6),
	struct('name', 'R4',  'orientation', 'x', 'value', 200e3, 'height', 500e-6),
	struct('name', 'R5', 'orientation', 'x', 'value', 200e3, 'height', 500e-6),
	struct('name', 'R6',  'orientation', 'x', 'value', 976e3, 'height', 500e-6),
	struct('name', 'R7', 'orientation', 'x', 'value', 953e3, 'height', 500e-6)
	struct('name', 'R8',  'orientation', 'x', 'value', 66.5e3, 'height', 500e-6),
	struct('name', 'R9', 'orientation', 'x', 'value', 68, 'height', 500e-6),
	struct('name', 'R10', 'orientation', 'x', 'value', 10e6, 'height', 500e-6),
};
capacitors = {
	struct('name', 'C1', 'orientation', 'x', 'value', 330e-12, 'height', 500e-6)
};
physical_constants;
lambda = c0/sqrt(3.68)/3e9;
coarse_resolution = lambda/80;
air_space = lambda/4;
tip_extend = 3e-3;
probe_gap = .5e-3;

% Get grid
mesh.x = CSX.RectilinearGrid.XLines;
mesh.y = CSX.RectilinearGrid.YLines;
mesh.z = CSX.RectilinearGrid.ZLines;

mesh.x(end+1) = min(mesh.x) - tip_extend - probe_gap;
mesh.x(end+1) = max(mesh.x);
mesh.y(end+1) = min(mesh.y);
mesh.y(end+1) = max(mesh.y);
mesh.z(end+1) = min(mesh.z) - air_space;
mesh.z(end+1) = max(mesh.z) + air_space;

%% 1. Add z levels for layers
for n=1:numel(layer_names)
	type = GetPropertyType(CSX, [layer_names{n} '_copper']);
	pos = GetPropertyPosition(CSX, type, [layer_names{n} '_copper']);
	prop_types = fieldnames(CSX.Properties.(type){pos}.Primitives);
	mesh.z(end+1) = CSX.Properties.(type){pos}.Primitives.(prop_types{1}){1}.ATTRIBUTE.Elevation;
	layer_height.(layer_names{n}) = CSX.Properties.(type){pos}.Primitives.(prop_types{1}){1}.ATTRIBUTE.Elevation;
end
% Ensure 4 cells between layers 1+2 and 3+4
mesh.z = [mesh.z, linspace(layer_height.('Bottom'), layer_height.('Signal/Power'), 5), linspace(layer_height.('Ground'), layer_height.('Top'), 5)];
mesh.x = [mesh.x, linspace(min(mesh.x), -tip_extend, 5)];

%% 2. Add components
% Materials
CSX = AddMetal(CSX, 'metal');
alumina_er = 9.4;
CSX = AddMaterial(CSX, 'alumina');
CSX = SetMaterialProperty(CSX, 'alumina', 'Epsilon', alumina_er);
for n=1:numel(resistors)
	[pad1_material, pad1_start, pad1_stop] = GetHyperLynxPort(CSX, [resistors{n}.name '.1']);
	[pad2_material, pad2_start, pad2_stop] = GetHyperLynxPort(CSX, [resistors{n}.name '.2']);
	if resistors{n}.value ~= 0
		CSX = AddLumpedElement(CSX, [resistors{n}.name '-' resistors{n}.orientation '-' num2str(resistors{n}.value)], resistors{n}.orientation, 'Caps', 0, 'R', resistors{n}.value);
	end
    if (strcmp(resistors{n}.orientation, 'x'))
        term1_start = [(pad1_start(1) + pad1_stop(1))/2, pad1_start(2), pad1_start(3)];
        term1_stop = [(pad1_start(1) + pad1_stop(1))/2, pad1_stop(2), pad1_start(3) + resistors{n}.height];
        term2_start = [(pad2_start(1) + pad2_stop(1))/2, pad2_start(2), pad1_start(3)];
        term2_stop = [(pad2_start(1) + pad2_stop(1))/2, pad2_stop(2), pad1_start(3) + resistors{n}.height];
        res_start = [(pad1_start(1) + pad1_stop(1))/2, pad1_start(2), pad1_start(3)+ resistors{n}.height];
        res_stop = term2_stop;
    else
        term1_start = [pad1_start(1), (pad1_start(2) + pad1_stop(2))/2, pad1_start(3)];
        term1_stop = [pad1_stop(1), (pad1_start(2) + pad1_stop(2))/2, pad1_start(3) + resistors{n}.height];
        term2_start = [pad2_start(1), (pad2_start(2) + pad2_stop(2))/2, pad1_start(3)];
        term2_stop = [pad2_stop(1), (pad2_start(2) + pad2_stop(2))/2, pad1_start(3) + resistors{n}.height];
        res_start = [pad1_start(1), (pad1_start(2) + pad1_stop(2))/2, pad1_start(3) + resistors{n}.height];
        res_stop = term2_stop;
    end
	CSX = AddBox(CSX, 'metal', 200, term1_start, term1_stop);
	CSX = AddBox(CSX, 'metal', 200, term2_start, term2_stop);
	CSX = AddBox(CSX, 'alumina', 150, term1_start, term2_stop);
	if resistors{n}.value ~= 0
		CSX = AddBox(CSX, [resistors{n}.name '-' resistors{n}.orientation '-' num2str(resistors{n}.value)], 300, res_start, res_stop);
	else
		CSX = AddBox(CSX, 'metal', 300, res_start, res_stop);
	end
	mesh = AddComponentMeshLines(mesh, term1_start, term2_stop);
end
for n=1:numel(capacitors)
	[pad1_material, pad1_start, pad1_stop] = GetHyperLynxPort(CSX, [capacitors{n}.name '.1']);
	[pad2_material, pad2_start, pad2_stop] = GetHyperLynxPort(CSX, [capacitors{n}.name '.2']);
	CSX = AddLumpedElement(CSX, [capacitors{n}.name '-' capacitors{n}.orientation '-' num2str(capacitors{n}.value)], capacitors{n}.orientation, 'Caps', 1, 'C', capacitors{n}.value);
    if (strcmp(capacitors{n}.orientation, 'x'))
        component_start = [min(pad1_stop(1), pad2_stop(1));pad1_start(2);pad1_start(3)];
        component_stop = [max(pad1_start(1), pad2_start(1));pad2_stop(2);pad1_start(3) + capacitors{n}.height];
    else
        component_start = [pad1_start(1);min(pad1_stop(2), pad2_stop(2));pad1_start(3)];
        component_stop = [pad2_stop(1);max(pad1_start(2), pad2_start(2));pad1_start(3) + capacitors{n}.height];
    end
    if capacitors{n}.value ~= 0
		CSX = AddBox(CSX, [capacitors{n}.name '-' capacitors{n}.orientation '-' num2str(capacitors{n}.value)], 300, component_start, component_stop);
	else
		CSX = AddBox(CSX, 'metal', 300, component_start, component_stop);
	end
	mesh = AddComponentMeshLines(mesh, component_start, component_stop);
end

%% 3. Add probe tip feature
% Probe tip
barrel_dia = 1.4e-3;
tip_dia = .5e-3;
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'J1.1');
component_start = [pad_start(1), (pad_start(2) + pad_stop(2) - barrel_dia)/2, pad_start(3)];
component_stop = [pad_stop(1), (pad_start(2) + pad_stop(2) + barrel_dia)/2, pad_start(3) + barrel_dia/2];
CSX = AddBox(CSX, 'metal', 300, component_start, component_stop);
component_start = [pad_start(1), (pad_start(2) + pad_stop(2))/2, pad_start(3) + barrel_dia/2];
component_stop = [pad_stop(1), (pad_start(2) + pad_stop(2))/2, pad_start(3) + barrel_dia/2];
CSX = AddCylinder(CSX, 'metal', 300, component_start, component_stop, barrel_dia/2);
component_start = [pad_start(1), (pad_start(2) + pad_stop(2))/2, pad_start(3) + barrel_dia/2];
component_stop = [-tip_extend, (pad_start(2) + pad_stop(2))/2, pad_start(3) + barrel_dia/2];
CSX = AddCylinder(CSX, 'metal', 300, component_start, component_stop, tip_dia/2);

%% 4. Meshing
% Force equidistant lines centered around the tip contact for measurement plane
mesh.z = [mesh.z, (pad_start(3) + barrel_dia/2) + min(abs(mesh.z - (pad_start(3) + barrel_dia/2)))*[-1:1]];

% Meshing for op amp input
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U2.3');
mesh.x = [mesh.x, linspace(pad_start(1), pad_stop(1), 3)]; % make sure this is odd so (start+stop)/2 is a mesh line
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'R9.2');
mesh.y = [mesh.y, linspace(pad_start(2), pad_stop(2), 4)];

% Add meshing for PCB copper pour capacitor
mesh = AddThirdsMeshLines(mesh, 6.6e-3, 8.3e-3, 13.5e-3, 15.4e-3, coarse_resolution/10);

% Via meshing: do this after components and snap to existing mesh lines when possible to avoid creating hyperfine detail
type = GetPropertyType(CSX, 'via');
pos = GetPropertyPosition(CSX, type, 'via');
for n=1:numel(CSX.Properties.(type){pos}.Primitives.('Cylinder'))
	prim = CSX.Properties.(type){pos}.Primitives.('Cylinder'){n};
	if min(mesh.x - prim.P1.ATTRIBUTE.X)^2 + min(mesh.y - prim.P1.ATTRIBUTE.Y)^2 > prim.ATTRIBUTE.Radius^2
		if min((mesh.x - prim.P1.ATTRIBUTE.X).^2) > prim.ATTRIBUTE.Radius^2
			mesh.x(end+1) = prim.P1.ATTRIBUTE.X;
		end
		if min((mesh.y - prim.P1.ATTRIBUTE.Y).^2) > prim.ATTRIBUTE.Radius^2
			mesh.y(end+1) = prim.P1.ATTRIBUTE.Y;
		end
	end
end

% Final mesh smoothing
mesh.x = RecursiveSmoothMesh(mesh.x, coarse_resolution, 1.5);
mesh.y = RecursiveSmoothMesh(mesh.y, coarse_resolution, 1.5);
mesh.z = RecursiveSmoothMesh(mesh.z, coarse_resolution, 1.5);
CSX = DefineRectGrid(CSX, 1, mesh);

%% 5. Ports
% Port 1 is the tip
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'J1.1');
portstart = [-tip_extend, (pad_start(2) + pad_stop(2))/2 - tip_dia/2, pad_start(3) + barrel_dia/2];
portstop  = [min(mesh.x), (pad_start(2) + pad_stop(2))/2 + tip_dia/2, pad_start(3) + barrel_dia/2];
[CSX,port{1}] = AddLumpedPort(CSX, 999, 1, 50, portstart, portstop, [1 0 0], 1 == excite_port);
% Port 2 is BUF802 input
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U1.2');
[gnd_material, gnd_start, gnd_stop] = GetHyperLynxPort(CSX, 'U1.17');
port_stop = [max(mesh.x(logical(mesh.x <= pad_stop(1)))), max(mesh.y(logical(mesh.y <= pad_stop(2)))), pad_start(3)];
port_start = [min(mesh.x(logical(mesh.x >= gnd_start(1)))), min(mesh.y(logical(mesh.y >= pad_start(2)))), pad_stop(3)];
[CSX, port{2}] = AddLumpedPort(CSX, 999, 2, 50, port_start, port_stop, [1 0 0], 2 == excite_port);
% Port 3 is BUF802 input bias
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U1.3');
port_stop = [max(mesh.x(logical(mesh.x <= pad_stop(1)))), max(mesh.y(logical(mesh.y <= pad_stop(2)))), pad_start(3)];
port_start = [min(mesh.x(logical(mesh.x >= gnd_start(1)))), min(mesh.y(logical(mesh.y >= pad_start(2)))), pad_stop(3)];
[CSX, port{3}] = AddLumpedPort(CSX, 999, 3, 50, port_start, port_stop, [1 0 0], 3 == excite_port);
% Port 4 is op amp + input
[pad_material, pad_start, pad_stop] = GetHyperLynxPort(CSX, 'U2.3');
port_stop = [(pad_start(1) + pad_stop(1))/2, max(mesh.y(logical(mesh.y <= pad_stop(2)))), pad_start(3)];
port_start = [(pad_start(1) + pad_stop(1))/2, min(mesh.y(logical(mesh.y >= pad_start(2)))), layer_height.('Ground')];
[CSX, port{4}] = AddLumpedPort(CSX, 999, 4, 50, port_start, port_stop, [0 0 1], 4 == excite_port);
