function mesh = CleanMesh(mesh, grid_duplicate_threshold)

% Remove duplicates and nearly-coincident lines
mesh.x = sort(mesh.x);
mesh.y = sort(mesh.y);
mesh.z = sort(mesh.z);
mesh.x = mesh.x(logical([1, diff(mesh.x) >= grid_duplicate_threshold]));
mesh.y = mesh.y(logical([1, diff(mesh.y) >= grid_duplicate_threshold]));
mesh.z = mesh.z(logical([1, diff(mesh.z) >= grid_duplicate_threshold]));
