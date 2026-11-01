function in = buildInput(cfg, row, data_dir)
% BUILDINPUT Outermost shell that formats configured sweeps, builds
% parameters, and sends everything to Simulink. Sets override from sweep, 
% which are passed along so not all default values in config.m don't apply.
%
% Function calls: 
%   build_params: Handles the busywork of manipulating the config data into
%   the right form.
sweep  = cfg.sweep;
ovr = cell(numel(sweep), 2); % 
for k = 1:numel(sweep)
    ovr(k,:) = {sweep(k).path, row.(sweep(k).name)};
end
if ~isempty(cfg.mc.seed_path)
    ovr(end+1,:) = {cfg.mc.seed_path, row.seed}; 
end
p  = build_params(cfg, data_dir, ovr);
in = Simulink.SimulationInput(cfg.sim.model);
for f = fieldnames(p)'    % envP, r, chute, launch, data
    in = in.setVariable(f{1}, p.(f{1}), 'Workspace', cfg.sim.model);
end
in = in.setModelParameter(cfg.sim.model_params{:});
end