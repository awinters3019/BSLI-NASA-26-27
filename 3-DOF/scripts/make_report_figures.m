%% make_report_figures.m
outdir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');
figdir = fullfile(outdir,'figures');  if ~exist(figdir,'dir'), mkdir(figdir); end
load(fullfile(outdir,'mc_profiles.mat'));              % M, PR, tgrid, cfg
good = M.ok & M.landed;   Mg = M(good,:);   limit = 2500;   % ft
winds = sort(unique(M.wind_mph))';

%% Table 1: summary by wind speed
Mg.within = abs(Mg.land_x_ft) < limit;
T = groupsummary(Mg, 'wind_mph', {'mean','std','max'}, ...
    {'apogee_ft','land_x_ft','max_speed_fps','max_acc_g_ascent','max_acc_g_descent', ...
    'touchdown_vz_fps'});
T.frac_within_2500 = groupsummary(Mg,'wind_mph','mean','within').mean_within;
writetable(T, fullfile(outdir,'report_table_by_wind.csv'));
disp(T(:, {'wind_mph','GroupCount','mean_apogee_ft','std_apogee_ft', ...
    'mean_land_x_ft','max_land_x_ft','frac_within_2500'}))

%% Fig 1: landing distance vs wind, with the requirement
f = figure('Position',[100 100 700 450]);
boxchart(categorical(Mg.wind_mph), Mg.land_x_ft); hold on
yline(limit,'r--','2500 ft limit','LineWidth',1.5);
xlabel('Mean wind [mph]'); ylabel('Landing downrange X [ft]'); grid on
title('Landing distance by wind speed');
exportgraphics(f, fullfile(figdir,'landing_by_wind.png'),'Resolution',300);

%% Fig 2: apogee histogram
f = figure('Position',[100 100 700 450]);
histogram(Mg.apogee_ft, 30); xlabel('Apogee [ft AGL]'); ylabel('Runs'); grid on
title(sprintf('Apogee (n=%d, mean %.0f ft, std %.0f ft)', ...
    height(Mg), mean(Mg.apogee_ft), std(Mg.apogee_ft)));
exportgraphics(f, fullfile(figdir,'apogee_hist.png'),'Resolution',300);

%% Fig 3: profile envelopes (median + 5-95%) per wind speed
prof = {'alt','Altitude [ft]'; 'x','Downrange X [ft]'; 'spd','Speed [ft/s]'; 'acc','Acceleration [g]'; 'theta','Pitch (radians)'};
cols = lines(numel(winds));
for p = 1:size(prof,1)
    f = figure('Position',[100 100 800 480]); hold on
    for i = 1:numel(winds)
        sel = good & M.wind_mph==winds(i);
        A = PR.(prof{p,1})(sel,:);
        alive = sum(~isnan(A),1) >= 0.5*sum(sel);        % hide the tail when most runs have landed
        lo = prctile(A,5,1);  md = prctile(A,50,1);  hi = prctile(A,95,1);
        tt = tgrid(alive);
        fill([tt; flipud(tt)], [lo(alive)'; flipud(hi(alive)')], cols(i,:), ...
            'FaceAlpha',0.15,'EdgeColor','none','HandleVisibility','off');
        plot(tt, md(alive), 'Color', cols(i,:), 'LineWidth',1.5, ...
            'DisplayName', sprintf('%d mph', winds(i)));
    end
    xlabel('Time [s]'); ylabel(prof{p,2}); legend('Location','best'); grid on
    exportgraphics(f, fullfile(figdir,['profile_' prof{p,1} '.png']),'Resolution',300);
end

%% Fig 4: landing scatter (cant vs wind, colored by landing X)
f = figure('Position',[100 100 700 450]);
scatter(Mg.wind_mph + 0.4*(rand(height(Mg),1)-0.5), Mg.cant_deg, 25, Mg.land_x_ft, 'filled');
colorbar; xlabel('Wind [mph]'); ylabel('Cant angle [deg]'); grid on
title('Landing X [ft] across the sampled conditions');
exportgraphics(f, fullfile(figdir,'landing_scatter.png'),'Resolution',300);

%% Sensitivity: standardized regression coefficients
X = zscore([Mg.wind_mph, Mg.cant_deg, Mg.P_psf, Mg.T_R]);
names = {'Wind','Cant','Pressure','Temperature'};
for out = {'apogee_ft','land_x_ft'}
    mdl_ = fitlm(X, Mg.(out{1}), 'VarNames', [names {out{1}}]);
    fprintf('\n%s: R^2 = %.3f\n', out{1}, mdl_.Rsquared.Ordinary);
    disp(mdl_.Coefficients(2:end,{'Estimate','pValue'}))
end

%% Events table
ev = varfun(@(x) [mean(x) std(x)], Mg, 'InputVariables', ...
    {'t_burnout','t_drogue','t_main','t_landed'});
disp(ev)

%% Descent time (apogee -> touchdown) requirement
t_desc_limit = 100;                                   % s
Mg.t_descent = Mg.t_landed - Mg.t_apogee_s;           % s
Mg.desc_ok   = Mg.t_descent <= t_desc_limit;

fprintf('\n=== Descent time (limit %d s) ===\n', t_desc_limit);
fprintf('Overall: %.1f%% within limit | mean %.1f s | std %.1f s | min %.1f s | max %.1f s\n', ...
    100*mean(Mg.desc_ok), mean(Mg.t_descent), std(Mg.t_descent), ...
    min(Mg.t_descent), max(Mg.t_descent));
fprintf('Worst-case margin: %.1f s | 95th percentile: %.1f s\n', ...
    t_desc_limit - max(Mg.t_descent), prctile(Mg.t_descent, 95));

% By wind speed
D = groupsummary(Mg, 'wind_mph', {'mean','std','min','max'}, 't_descent');
D.pct_within_100s = 100*groupsummary(Mg,'wind_mph','mean','desc_ok').mean_desc_ok;
disp(D)
writetable(D, fullfile(outdir,'report_table_descent_time.csv'));

% Both requirements at once (drift AND descent time)
both_ok = abs(Mg.land_x_ft) < limit & Mg.desc_ok;
fprintf('Meet BOTH drift (<%d ft) and descent time (<%d s): %.1f%% of runs\n', ...
    limit, t_desc_limit, 100*mean(both_ok));

% Figure: descent time vs wind
f = figure('Position',[100 100 700 450]);
boxchart(categorical(Mg.wind_mph), Mg.t_descent); hold on
yline(t_desc_limit,'r--','100 s limit','LineWidth',1.5);
xlabel('Mean wind [mph]'); ylabel('Descent time, apogee to touchdown [s]'); grid on
title('Descent time by wind speed');
exportgraphics(f, fullfile(figdir,'descent_time_by_wind.png'),'Resolution',300);