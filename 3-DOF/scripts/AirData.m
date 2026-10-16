function air = AirData(env, state, rocket)
%#codegen
% earth -> body (same convention as gravity: Fx=-mg*sin(theta))
wu =  cos(state.theta)*env.wind_xe - sin(state.theta)*env.wind_ze;
ww =  sin(state.theta)*env.wind_xe + cos(state.theta)*env.wind_ze;

U_rel = state.U - wu;
W_rel = state.W - ww;
V     = sqrt(U_rel^2 + W_rel^2);

% Fade alpha to 0 at low airspeed (fixes the atan2 noise near apogee and pad)
alpha = atan2(W_rel, U_rel) * min(V/rocket.Vmin, 1);

air = struct('U_rel',U_rel,'W_rel',W_rel,'V',V,'alpha',alpha, ...
             'Mach',V/env.a,'qdyn',0.5*env.rho*V^2);
end