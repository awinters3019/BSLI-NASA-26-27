function in = buildInput(mdl, row, envP0, launch0, cfg)
% mdl     : model name (char)
% row     : one row of the runs table (P_psf, T_R, cant_deg, wind_mph, gust_seed)
% envP0   : baseline envP from initialize_vars (gust settings live in here)
% launch0 : baseline launch struct from initialize_vars
% cfg     : MonteCarlo config struct (gust_frac, sim_stop)

wind_fps = row.wind_mph*5280/3600;           % mph -> ft/s
sigma    = cfg.gust_frac*wind_fps;           % gust RMS, ft/s

% --- environment overrides (everything gust-related is inside envP) ---
envP = envP0;
envP.T_ground   = row.T_R;
envP.P_ground   = row.P_psf;
envP.wind_speed = wind_fps;
envP.gust_sigma = sigma;
envP.gust_seed  = row.gust_seed;
envP.gust_gain  = sigma*sqrt(2*envP0.gust_tau); % gust_tau stays at baseline

% --- launch override: theta from +x_e, pi/2 = straight up ---
launch = launch0;
launch.theta0 = pi/2 + cfg.cant_sign*deg2rad(row.cant_deg);

% --- Make sure Monte Carlo's desired variables don't get overwritten
in = Simulink.SimulationInput(mdl);
in = in.setVariable('envP',   envP,   'Workspace', mdl);   % model workspace wins over InitFcn
in = in.setVariable('launch', launch, 'Workspace', mdl);
in = in.setModelParameter('StopTime', num2str(cfg.sim_stop), ...
                              'InspectSignalLogs', 'off');
end