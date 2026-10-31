%% tumble_check.m -- flag runs that swing or tumble after drogue deployment
outdir = fullfile(fileparts(fileparts(mfilename('fullpath'))),'results');
L = load(fullfile(outdir,'mc_profiles.mat'),'M','PR','tgrid');
M = L.M;  PR = L.PR;  tg = L.tgrid;

th_ref = -pi/2;                    % settled attitude from your plot (nose down)
settle = 5;                        % s after drogue to skip the deployment flip
wrap   = @(x) atan2(sin(x), cos(x));

n = height(M);
[M.dev_max, M.frac_off, M.q_rms, M.q_max, M.revs] = deal(nan(n,1));

for i = 1:n
    if ~(M.ok(i) && M.landed(i)), continue; end
    th = double(PR.theta(i,:))';  q = double(PR.q(i,:))';            % extract theta, q
    v = ~isnan(th) & ~isnan(q);   t = tg(v);  th = th(v);  q = q(v); % No NaNs
    w = t >= M.t_drogue(i)+settle & t <= M.t_landed(i)-1;   % descent, minus ground impact
    if nnz(w) < 5, continue; end

    dev = abs(wrap(th(w) - th_ref));          % angle away from the nominal attitude
    M.dev_max(i)  = max(dev);
    M.frac_off(i) = mean(dev > pi/2);         % fraction of time >90 deg off nominal
    M.q_rms(i)    = rms(q(w));
    M.q_max(i)    = max(abs(q(w)));
    thu = unwrap(th(w));
    M.revs(i)     = (max(thu) - min(thu))/(2*pi);   % full rotations during descent
end

M.tumbled = M.revs >= 1 | M.frac_off > 0.25;        % starting thresholds, calibrate below
G = M(M.ok & M.landed, :);
disp(groupsummary(G, 'wind_mph', @(x) 100*mean(x), 'tumbled'))   % % tumbled by wind

bad  = find(M.tumbled, 3);   good = find(~M.tumbled & M.ok & M.landed, 3);
figure; hold on
for i = bad',  plot(tg, double(PR.theta(i,:)), 'r', "LineWidth", 1); end
for i = good', plot(tg, double(PR.theta(i,:)), 'g', "LineWidth", 1); end
xlabel('Time [s]'); ylabel('Pitch [rad]'); grid on
