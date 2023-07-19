function pos = GetPropertyPosition(CSX, type, name)
% function pos = GetPropertyPosition(CSX, type, name)
%
%   - internal function to get the position of property with name: <name>
%       inside a given type
%   - function will perform a series of validitiy tests
%   - will return 0 if not found
%
% CSXCAD matlab interface
% -----------------------
% author: Thorsten Liebig (c) 2013

pos = 0;

if ~ischar(name)
    error('CSXCAD::GetPropertyPosition: name must be a string');
end

if ~ischar(type)
    error('CSXCAD::GetPropertyPosition: type name must be a string');
end

if ~isfield(CSX,'Properties')
    error('CSXCAD:GetPropertyPosition','CSX.Properties is not defined');
end

if isempty(type)
    error('CSXCAD:GetPropertyPosition','type is empty, maybe the property you requested is undefined');
end

% type not (yet) defined, thus <name> not found
if ~isfield(CSX.Properties,type)
    return
end

for n=1:numel(CSX.Properties.(type))
   if  strcmp(CSX.Properties.(type){n}.ATTRIBUTE.Name, name)
       pos=n;
       return
   end
end
