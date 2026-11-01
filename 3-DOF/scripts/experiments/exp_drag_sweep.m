% scripts/experiments/exp_drag_sweep.m  ------- Example
% Example of how to document a configuration you did; running this script
% (i.e. typing >> exp_drag_sweep in the command window) will run this
% specific Monte Carlo values.
% reproduce a Monte Carlo simulation that you want.


cfg = config(); % Assign in all default values
% Below, these values will be overwritten from the default.
cfg.name = 'drag_sweep';   % name of generated repo for these results
cfg.mc.mode = 'lhs';      % Choices: grid | lhs | random
cfg.mc.n_samples = 96;
cfg.mc.n_pilot = 0;
cfg.params.envP.wind_mph = 5;  % fixed for this study (replaces default)
cfg.sweep = [ sweepVar('r.k_cd', 'range', [1 1.25], 'name','k_cd')
    sweepVar('chute.Cd_main','range', [2.59 2.92], 'name','Cd_main') ];
MonteCarlo(cfg) % Runs Monte Carlo on your config.