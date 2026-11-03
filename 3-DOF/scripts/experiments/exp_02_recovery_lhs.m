%% exp_02_recovery_lhs.m
% QUESTION: Which recovery parameters drive descent time (<100 s) and drift 
%           (<2500 ft)?
% MODE:     lhs (space-filling over continuous ranges)
% SIZE:     400 samples; wind fixed at 15 mph
PILOT = true;

exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
cfg.name = 'exp02_recovery_lhs';
cfg.params.envP.wind_mph = 15;                          % fixed for this study

cfg.sweep = [
    sweepVar('chute.main_alt',      'range', [600 1000],    'name','main_alt')    % ft AGL
    sweepVar('chute.d_drogue_in',   'range', [20 28],       'name','d_drogue_in')
    sweepVar('chute.Cd_drogue',     'range', [1.0 1.3],     'name','Cd_drogue')
    sweepVar('chute.Cd_main',       'range', [2.59 2.92],   'name','Cd_main')     % measured to manufacturer
    sweepVar('chute.tau_infl',      'range', [0.3 1.0],     'name','tau_infl')
    ];

cfg.mc.mode      = 'lhs';
cfg.mc.n_samples = 400;
cfg.mc.n_pilot   = 10*PILOT;

MonteCarlo(cfg)

%% ---- Quick look: rank correlation of each input with the outputs ----
if ~PILOT
    G = readtable(fullfile(fileparts(scripts_dir), 'results', cfg.name, 'mc_summary.csv'));
    G.t_descent = G.t_landed - G.t_apogee_s;
    G = G(G.ok & G.landed, :);
    ins  = {cfg.sweep.name};
    outs = {'t_descent','land_x_ft','max_acc_g_descent','touchdown_vz_fps'};
    R = array2table(corr(G{:,ins}, G{:,outs}, 'Type','Spearman'), ...
        'VariableNames', outs, 'RowNames', ins);
    disp(R)
    fprintf('%.1f%% of runs meet descent time <= 100 s\n', 100*mean(G.t_descent <= 100));
end