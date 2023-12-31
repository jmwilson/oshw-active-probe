function type_name = GetPropertyType(CSX, name)
% function type_name = GetPropertyType(CSX, name)
%
% internal function to get the type of a given property
%
% CSXCAD matlab interface
% -----------------------
% author: Thorsten Liebig (c) 2010-2013

if ~ischar(name)
    error('CSXCAD::GetPropertyType: name must be a string');
end
if ~isfield(CSX,'Properties')
    error('CSXCAD:GetPropertyPosition','CSX.Properties is not defined');
end

type_name = '';
if isempty(CSX.Properties)
    return
end

prop_types = fieldnames(CSX.Properties);
for n=1:numel(prop_types)
    for p = 1:numel(CSX.Properties.(prop_types{n}))
        if (strcmp(CSX.Properties.(prop_types{n}){p}.ATTRIBUTE.Name,name))
            type_name = prop_types{n};
            return;
        end
    end
end
