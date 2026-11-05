function F = extract_fullres(out, p, dt)
%EXTRACT_FULLRES  Pull full-resolution signals from ONE run onto a uniform time grid.
%   out: SimulationOutput from sim.  p: params struct from build_params.  dt: grid step [s].
if nargin < 3, dt = 0.02; end
if ~isempty(out.ErrorMessage), error('Run failed: %s', out.ErrorMessage); end
logs = out.logsout;

% Variable-step logs have irregular times, so resample everything onto one uniform grid
[tz, ~] = grab(logs, 'StateBus', 'Z');
t = (0:dt:tz(end))';
F.t = t;  F.dt = dt;
rs = @(ts, d, how) interp1(ts, d, t, how, 'extrap');

for nm = {'X','Z','U','W','theta','q'}
    [ts, d] = grab(logs, 'StateBus', nm{1});   F.(nm{1}) = rs(ts, d, 'linear');
end
for nm = {'alpha','U_rel','W_rel','V','Mach'}
    [ts, d] = grab(logs, 'Air', nm{1});     F.(nm{1}) = rs(ts, d, 'linear');
end
for nm = {'phase','drogue_cmd','main_cmd'}
    [ts, d] = grab(logs, 'phase', nm{1});     F.(nm{1}) = rs(ts, d, 'previous');
end
F.drogue_fail = p.chute.DrogueFail; % just for fancy phase titling
F.main_fail   = p.chute.MainFail;
F.main_alt    = p.chute.main_alt;

[ts, d] = grab(logs, 'EnvBus',  'wind_xe');    F.wind_xe = rs(ts, d, 'linear');
[ts, d] = grab(logs, 'MassBus', 'CG');         F.CG    = rs(ts, d, 'linear');

% Force/moment vectors [Fx; Fz; M] from each subsystem
src = {'thr','FM_thrust'; 'aero','FM_aero'; 'chute','FM_chute'};
for k = 1:size(src,1)
    [ts, D] = grab(logs, src{k,2});            % D is N x 3
    F.(['Fx_' src{k,1}]) = rs(ts, D(:,1), 'linear');
    F.(['Fz_' src{k,1}]) = rs(ts, D(:,2), 'linear');
    F.(['M_'  src{k,1}]) = rs(ts, D(:,3), 'linear');
end
F.Fx = F.Fx_thr + F.Fx_aero + F.Fx_chute;      % net applied force, body x [lbf]
F.Fz = F.Fz_thr + F.Fz_aero + F.Fz_chute;      % net applied force, body z [lbf] (gravity is NOT included)


% Find effective center of pressure over time (hi Liav!)
% The dynamic pressure q*S cancels in the ratio, so only alpha and Mach are needed
r  = p.r;                                         % Get rocket geometry
Mc = min(F.Mach, 0.9);                            
sa = sin(F.alpha);  ca = cos(F.alpha);
Np = (r.CNa_pot ./ sqrt(1 - Mc.^2)) .* sa .* ca;  % Potential-flow normal force / (q*S)
Nc = (r.Cdc*r.Aplan/r.S) * abs(sa) .* sa;         % Crossflow normal force / (q*S)
xcp = (Np*r.x_cp_pot + Nc*r.x_cf) ./ (Np + Nc);   % Calculate CP from potential and crossflow normals
xcp(abs(sa) < 1e-3) = r.x_cp_pot;                 % If alpha ~ 0: replace with potential-flow CP
xcp = min(max(xcp, 0), r.L);                      % Keep it on the rocket body
xcp(F.V < r.Vmin | ~isfinite(xcp)) = NaN;         % If airspeed is too low, it's meaningless --> NaN
F.xcp = xcp;                                      % ft from nose tip

F.r = r;  F.chute = p.chute;                      % geometry for the viewer
end

function [t, d] = grab(logs, name, field)
% Returns time (N x 1) and data (N x k) for a logged signal or one field of a logged bus
el = logs.get(name);
if isempty(el), error('Signal "%s" is not logged. Right-click the wire -> Log Selected Signals.', name); end
if isa(el, 'Simulink.SimulationData.Dataset'), el = el{1}; end
v = el.Values;
if nargin > 2, v = v.(field); end
t = v.Time(:);
d = double(v.Data);
if ndims(d) == 3, d = permute(d, [3 1 2]); end        % [rows cols N] -> [N rows cols]
d = reshape(d, numel(t), []);
[t, iu] = unique(t);  d = d(iu, :);  % variable-step solvers can repeat timestamps
end