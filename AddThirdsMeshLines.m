function mesh = AddThirdsMeshLines(mesh, x1, x2, y1, y2, resolution)

xmin = min(x1, x2);
xmax = max(x1, x2);

ymin = min(y1, y2);
ymax = max(y1, y2);

if min(abs(mesh.x - (xmin + resolution/2))) > resolution/2
	mesh.x(end+1) = xmin + resolution/2;
end
if min(abs(mesh.x - (xmin - 2*resolution/2))) > resolution/2
	mesh.x(end+1) = xmin - 2*resolution/2;
end
if min(abs(mesh.x - (xmax - resolution/2))) > resolution/2
	mesh.x(end+1) = xmax - resolution/2;
end
if min(abs(mesh.x - (xmax + 2*resolution/2))) > resolution/2
	mesh.x(end+1) = xmax + 2*resolution/2;
end

if min(abs(mesh.y - (ymin + resolution/2))) > resolution/2
	mesh.y(end+1) = ymin + resolution/2;
end
if min(abs(mesh.y - (ymin - 2*resolution/2))) > resolution/2
	mesh.y(end+1) = ymin - 2*resolution/2;
end
if min(abs(mesh.y - (ymax - resolution/2))) > resolution/2
	mesh.y(end+1) = ymax - resolution/2;
end
if min(abs(mesh.y - (ymax + 2*resolution/2))) > resolution/2
	mesh.y(end+1) = ymax + 2*resolution/2;
end
% mesh.x = [mesh.x, xmin - [-resolution/2, 2*resolution/2], xmax + [-resolution/2, 2*resolution/2]];
% mesh.y = [mesh.y, ymin - [-resolution/2, 2*resolution/2], ymax + [-resolution/2, 2*resolution/2]];
