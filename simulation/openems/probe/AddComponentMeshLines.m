function mesh = AddComponentMeshLines(mesh, component_start, component_stop)

mesh.x(end+1) = component_start(1);
mesh.x(end+1) = component_stop(1);
mesh.y(end+1) = component_start(2);
mesh.y(end+1) = component_stop(2);
mesh.z(end+1) = component_start(3);
mesh.z(end+1) = component_stop(3);
