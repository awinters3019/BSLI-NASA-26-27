function FM = BodyAero(state, air, env, ms, burning, r)
% BODYAERO  Function called by Simulink MATLAB Function block.
% From the other buses and existing rocket geometry, calculates the
% aerodynamic forces and moments due to rocket body geometry, primarily
% with Barrowman equations.

%#codegen
q  = air.qdyn;
sa = sin(air.alpha);  ca = cos(air.alpha);
M  = min(air.Mach, 0.9);

% --- Normal force: two parts, both odd in alpha, valid for ALL alpha ---
CNa   = r.CNa_pot / sqrt(1 - M^2);          % Prandtl-Glauert
N_pot = CNa * sa*ca * q*r.S;                % slender-body (Barrowman) part
N_cf  = r.Cdc*(r.Aplan/r.S) * abs(sa)*sa * q*r.S; % crossflow part (tumble)

% --- Axial force ---
CA = DragCoeff(air, env, burning, r);
Fx = -q*r.S*CA*ca;
Fz = -(N_pot + N_cf);

% --- Moment about CG (arms are aft-positive from CG) ---
M_n = -( N_pot*(r.x_cp_pot - ms.CG) + N_cf*(r.x_cf - ms.CG) );
M_d = q*r.S*r.d * (r.Cmq * state.q * r.d / (2*max(air.V, r.Vmin))); % pitch damping, Cmq<0

FM = [Fx; Fz; M_n + M_d];
end

function CA = DragCoeff(air, env, burning, r)
M  = min(air.Mach, 0.95);
Re = max(env.rho*air.V*r.L/env.mu, 1e5);
Cf = 0.455/log10(Re)^2.58 / (1 + 0.144*M^2)^0.65; % turbulent, compressible

Cd_body = Cf*r.fb*r.Swet_body/r.S;                % skin friction w/ form factor
Cd_fins = Cf*(1 + 2*r.t_fin/r.c_fin)*r.Swet_fins/r.S;
Cd_base = (0.12 + 0.13*M^2)*(1 - burning)*r.Abase_ratio;
Cd_wave = r.Cdw_pk*max(0, (M - 0.8)/0.15)^2; % zero for our rocket (M = 0.6 max)
CA = r.k_cd*(Cd_body + Cd_fins + Cd_base + Cd_wave + r.Cd_extra);
end
