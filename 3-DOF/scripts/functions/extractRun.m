function [m, p] = extractRun(out, tg, cfg)
% EXTRACTRUN  Monte Carlo helper function for the logging of individual 
% runs, and summaries in a batch file.
% Can be edited to have extra variables saved beyond the defaults.
nt = numel(tg);
m = struct('ok',false, 'landed',false, 'apogee_ft',NaN, 't_apogee_s',NaN, ...
    'max_speed_fps',NaN, 'max_acc_g_ascent',NaN, 'max_acc_g_descent',NaN, ...
    'land_x_ft',NaN, 'max_abs_x_ft',NaN, 'flight_time_s',NaN, ...
    'touchdown_vz_fps',NaN, 'max_q_radps',NaN, ...
    't_boost',NaN, 't_burnout',NaN, 't_drogue',NaN, 't_maindelay',NaN, ...
    't_main',NaN, 't_landed',NaN, 'T0_logged',NaN, 'P0_logged',NaN, 'err',"");
names = {'alt','x','spd','acc'};

% ADD EXTRA VARIABLES TO TRACK HERE AS DESIRED
if cfg.out.save_extras, names = [names {'theta','q'}]; end

p = struct();
for n = names, p.(n{1}) = nan(1, nt, 'single'); end

if ~isempty(out.ErrorMessage),m.err = string(out.ErrorMessage); return; end
try
    logs = out.logsout;
    mx = @(v) max([v(:); NaN], [], 'omitnan');

    % --- states (StateBus) ---
    st = logs.get('StateBus').Values;
    [t, iu] = unique(st.Z.Time);
    g = @(ts) double(ts.Data(iu));
    Z = g(st.Z); 
    X = g(st.X); 
    U = g(st.U); 
    W = g(st.W);
    th = g(st.theta); 
    q = g(st.q);
    alt = -Z;  
    spd = hypot(U, W);

    % --- acceleration (block output A_xb, A_zb) ---
    ac = logs.get('Acc').Values;
    A  = reshape(ac.Data, numel(ac.Time), []);
    [ta, ia] = unique(ac.Time);
    accg = hypot(A(ia,1), A(ia,2))/32.174;       % Convert to g forces

    % --- phase transition times (Pad=0 ... Landed=6) ---
    phts = logs.get('phase').Values.phase; % pick the 'phase' field of the chart's output bus
    [tp, ip] = unique(phts.Time);  phv = double(phts.Data(ip));
    tph = nan(1,6);
    for k = 1:6
        i = find(phv >= k, 1);
        if ~isempty(i), tph(k) = tp(i); end
    end
    m.t_boost = tph(1); m.t_burnout = tph(2); m.t_drogue = tph(3);
    m.t_maindelay = tph(4); m.t_main = tph(5); m.t_landed = tph(6);
    m.landed = ~isnan(tph(6));

    % --- launch-condition check (did the overrides land?) ---
    env = logs.get('EnvBus').Values;
    m.T0_logged = double(env.T.Data(1));
    m.P0_logged = double(env.P.Data(1));

    % --- summary metrics ---
    [m.apogee_ft, iap]  = max(alt);
    m.t_apogee_s        = t(iap);
    m.max_speed_fps     = max(spd);
    m.max_acc_g_ascent  = mx(accg(ta <= m.t_apogee_s));
    m.max_acc_g_descent = mx(accg(ta >  m.t_apogee_s));
    m.land_x_ft  = X(end);   
    m.max_abs_x_ft = max(abs(X));
    m.flight_time_s = t(end);
    vz = gradient(alt, t);
    m.touchdown_vz_fps = mean(vz(t > t(end)-2));   % negative = descending
    m.max_q_radps = max(abs(q));
    m.ok = true;

    % --- profiles on a common time grid (NaN after the run ends) ---
    raw = struct('alt',{{t,alt}}, 'x',{{t,X}}, 'spd',{{t,spd}}, ...
        'acc',{{ta,accg}}, 'theta',{{t,th}}, 'q',{{t,q}});
    for n = names
        r = raw.(n{1});
        p.(n{1}) = single(interp1(r{1}, r{2}, tg, 'linear', NaN))';
    end
catch ME
    m.err = string(ME.message); 
end
end