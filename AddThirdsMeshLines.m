function mesh = AddThirdsMeshLines(mesh, x1, x2, y1, y2, resolution)

xmin = min(x1, x2);
xmax = max(x1, x2);

ymin = min(y1, y2);
ymax = max(y1, y2);

mesh.x = [mesh.x, xmin - [-resolution/3, 2*resolution/3], xmax + [-resolution/3, 2*resolution/3]];
mesh.y = [mesh.y, ymin - [-resolution/3, 2*resolution/3], ymax + [-resolution/3, 2*resolution/3]];
