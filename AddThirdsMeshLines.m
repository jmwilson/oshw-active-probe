function mesh = AddThirdsMeshLines(mesh, x1, x2, y1, y2, resolution)

xmin = min(x1, x2);
xmax = max(x1, x2);

ymin = min(y1, y2);
ymax = max(y1, y2);

mesh.x(end+1) = xmin - resolution/3;
mesh.x(end+1) = xmin + 2*resolution/3;
mesh.x(end+1) = xmax - 2*resolution/3;
mesh.x(end+1) = xmax + resolution/3;

mesh.y(end+1) = ymin - resolution/3;
mesh.y(end+1) = ymin + 2*resolution/3;
mesh.y(end+1) = ymax - 2*resolution/3;
mesh.y(end+1) = ymax + resolution/3;
