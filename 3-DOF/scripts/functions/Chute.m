function FM = Chute(s, air, env, ms, CdS, r)
% CHUTE  Function called by Simulink MATLAB Function block.
% Taking from each of the other buses and rocket/chute geometry,
% calculates the forces and moments to be applied based on which chutes are
% out, where the parachutes attach, and basic drag equations.

x_att = ms.CG - r.x_attach;        % attach point forward of CG [ft]
u_pt  = air.U_rel;
w_pt  = air.W_rel - s.q*x_att;     % rotation changes attach-point velocity
V_pt  = sqrt(u_pt^2 + w_pt^2);

Fx = -0.5*env.rho*CdS*V_pt*u_pt;   % always opposes velocity
Fz = -0.5*env.rho*CdS*V_pt*w_pt;
FM = [Fx; Fz; -x_att*Fz];          % moment from the force, about the CG
end