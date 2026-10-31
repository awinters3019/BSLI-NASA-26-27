function out = run_single(cfg, ovr)
    % cfg = config(); cfg.params.envP.wind_mph = 15; out = run_single(cfg);
    % Optional ovr = {'envP.T_ground', 520; 'launch.cant_deg', 7}
    if nargin < 1, cfg = config(); end
    if nargin < 2, ovr = cell(0,2); end
    scripts_dir = fileparts(which('config'));
    data_dir = fullfile(fileparts(scripts_dir), 'data');
    load_system(cfg.sim.model);
    p  = build_params(cfg, data_dir, ovr);
    in = Simulink.SimulationInput(cfg.sim.model);
    for f = fieldnames(p)'
        in = in.setVariable(f{1}, p.(f{1}), 'Workspace', cfg.sim.model);
    end
    in  = in.setModelParameter(cfg.sim.model_params{:});
    out = sim(in);
    writeSnapshot(cfg, fullfile(fileparts(scripts_dir), 'results',...
        ['single_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]));
end