%% exp_03_aero_uncertainty_random.m
% QUESTION: How much do uncertain aero tuning knobs and mass properties
%           widen the apogee and drift spread, on top of weather?
% MODE:     random (independent uniform draws; discrete levels balanced)
% SIZE:     600 samples
PILOT = true;

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp03_aero_uncertainty_random';

cfg.sweep = [
    % model uncertainty (continuous)
    sweepVar('r.k_cd',            'range',  [1 1.3], 'name','k_cd')          % overall drag scale
    sweepVar('r.Cd_extra',        'range',  [0.01 0.05], 'name','Cd_extra')      % rail buttons, lugs
    sweepVar('r.Cmq',             'range',  [-20 -5],    'name','Cmq')           % pitch damping
    sweepVar('mass.mass_start_lbm','range', [50.5 52.5], 'name','m0_lbm')
    sweepVar('mass.CG_start_ft',  'range',  [7.10 7.35], 'name','CG0_ft')
    % conditions (continuous + discrete)
    sweepVar('launch.cant_deg',   'range',  [5 10],      'name','cant_deg')
    sweepVar('envP.wind_mph',     'levels', [0 5 10 15 20], 'name','wind_mph')   % balanced across runs
    ];

cfg.mc.mode      = 'random';
cfg.mc.n_samples = 600;
cfg.mc.rng_seed  = 7;    % change for an independent draw
cfg.mc.n_pilot   = 10*PILOT;

MonteCarlo(cfg)