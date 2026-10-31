% scripts/experiments/exp_drag_sweep.m
% Example of how to document a configuration you did; running this will
% reproduce a Monte Carlo simulation that you want.
cfg = config(); % Assign in all default values
cfg.name = 'drag_sweep';
cfg.mc.mode = 'lhs';  cfg.mc.n_samples = 500;
cfg.params.envP.wind_mph = 15;  % fixed for this study (replaces default)
cfg.sweep = [ sweepVar('r.k_cd', 'range', [0.9 1.2], 'name','k_cd')
    sweepVar('chute.Cd_main','range', [2.59 2.92], 'name','Cd_main') ];
MonteCarlo(cfg) % Runs Monte Carlo on your config.