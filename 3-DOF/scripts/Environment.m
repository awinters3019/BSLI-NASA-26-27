function env = Environment(Z,gust,envP)
%#codegen
% Z: earth-frame z, DOWN [ft].  gust: [ft/s].
h  = max(-Z, 0);                         % altitude AGL [ft]

g0  = 32.174;                            % ft/s^2
R   = 1716.49;                           % ft*lbf/(slug*degR), air
gam = 1.4;
Lr  = 0.00356616;                        % lapse rate [degR/ft] (= 0.0065 K/m)

T   = envP.T_ground - Lr*h;              % degR
P   = envP.P_ground * (T/envP.T_ground)^(g0/(R*Lr));   % psf
rho = P/(R*T);                           % slug/ft^3
a   = sqrt(gam*R*T);                     % ft/s
mu  = 2.27e-8*T^1.5/(T + 198.72);        % slug/(ft*s), Sutherland in degR

% Wind: 1/7 power-law shear on the in-plane component, plus gust (inactive)
w_mean = envP.wind_speed*cos(envP.wind_dir); % * (max(h,1)/envP.h_ref)^(1/7);

env = struct('rho',rho,'a',a,'T',T,'P',P,'mu',mu, ...
             'wind_xe', w_mean + gust, 'wind_ze', 0);   % order = EnvBus
end