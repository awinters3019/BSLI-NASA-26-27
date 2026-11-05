%% exp_04_single_run.m
% QUESTION: What does ONE specific case look like? (no sweep / pool)
exp_dir = fileparts(mfilename('fullpath'));  scripts_dir = fileparts(exp_dir);
addpath(scripts_dir, fullfile(scripts_dir,'functions'));

cfg = config();
ovr = { 'envP.wind_mph', 20      % overrides: {path, value}
    'launch.cant_deg',   10
    'envP.gust_seed',    3
    'chute.main_alt',    700 };

out = run_single(cfg, ovr, true);      % writes a snapshot to results/single_<time>/
disp(out.ErrorMessage)                 % empty = the run itself worked

tgrid = (0:cfg.out.dt:cfg.out.t_max)';
[m, p] = extractRun(out, tgrid, cfg);
disp(m)                                % summary metrics for this run

figure; tiledlayout(2,1)
nexttile; plot(tgrid, p.alt, 'LineWidth',1.5); 
grid on; ylabel('Altitude [ft]')
nexttile; plot(tgrid, p.x,   'LineWidth',1.5); 
grid on; ylabel('Drift X [ft]'); 
xlabel('Time [s]')