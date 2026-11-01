function p = build_params(cfg, data_dir, ovr)
% BUILD_PARAMS  Function shell which calls functions to turn config inputs 
% into more useful/derived forms. If override cell (ovr) is supplied, build
% params with setByPath so default values from config.m are overwritten.
% This function calls:
%   setByPath: Sets overrides on parameters.
%   derive_params: Does much of the actual work in creating derived
%     constants and variables.
%   load_data: Opens spreadsheets in 3-DOF/data and creates a cache and
%     vectors containing this data.
%   mass_vectors: From config mass variables, turns them into vectors which
%     can be used by Simulink blocks.

% ovr: Nx2 cell {path, value; ...} applied to the raw inputs BEFORE 
% deriving.
p = cfg.params;
if nargin > 2 % if ovr was received
    for k = 1:size(ovr,1)
    p = setByPath(p, ovr{k,1}, ovr{k,2}); 
    end
end
p = derive_params(p);
d = load_data(cfg, data_dir);     % thrust only (cached)
if istable(d)
    d = table2struct(d, 'ToScalar', true);  % columns become fields
end
p.data = d;
md = mass_vectors(p.mass);        % rebuilt every run, so sweeps work
for f = fieldnames(md)'
    p.data.(f{1}) = md.(f{1});
end
p = rmfield(p,'mass'); % just doesn't need to be sent through
end