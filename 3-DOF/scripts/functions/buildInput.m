function in = buildInput(cfg, row, data_dir)
    sw  = cfg.sweep;
    ovr = cell(numel(sw), 2);
    for k = 1:numel(sw), ovr(k,:) = {sw(k).path, row.(sw(k).name)}; end
    if ~isempty(cfg.mc.seed_path), ovr(end+1,:) = {cfg.mc.seed_path, row.seed}; end
    p  = build_params(cfg, data_dir, ovr);
    in = Simulink.SimulationInput(cfg.sim.model);
    for f = fieldnames(p)'    % envP, r, chute, launch, data
        in = in.setVariable(f{1}, p.(f{1}), 'Workspace', cfg.sim.model);
    end
    in = in.setModelParameter(cfg.sim.model_params{:});
end