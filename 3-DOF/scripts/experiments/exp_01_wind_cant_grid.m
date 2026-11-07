%% exp_01_wind_cant_grid.m
% QUESTION: How do landing drift and apogee depend on wind speed, cant angle,
%           and tilt direction (into the wind vs. with it)?
% MODE:     grid (every combination, n_reps gust seeds each)
% SIZE:     4 cant x 2 directions x 5 winds x 10 reps (0 mph keeps 1 rep) 
%           = 328 runs
PILOT = true;                                   % true = 10-run smoke test

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp01_wind_cant_grid';

cfg.sweep = [
    sweepVar('envP.wind_mph',    'levels', [0 5 10 15 20], 'name','wind_mph')
    sweepVar('launch.cant_deg',  'levels', [5 6.7 8.3 10],  'name','cant_deg')
    sweepVar('launch.cant_sign', 'levels', [+1 -1],         'name','cant_sign')  % +1 into wind, -1 with wind
    ];

cfg.mc.mode          = 'grid';
cfg.mc.n_reps        = 6;                      % gust seeds per condition
cfg.mc.single_rep_if = @(T) T.wind_mph == 0;    % no gusts at 0 mph, so one rep is enough
cfg.mc.n_pilot       = 10*PILOT;

MonteCarlo(cfg)