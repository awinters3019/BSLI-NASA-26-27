function p = derive_params(p)
% Computes everything the model reads from the INPUTS. 
% Sweep inputs but never these parameters.
in2ft = 1/12;
e = p.envP;
e.wind_speed = e.wind_mph*5280/3600;                % ft/s
e.gust_sigma = e.gust_frac*e.wind_speed;
e.gust_Ts    = e.gust_tau/10;
e.gust_gain  = e.gust_sigma*sqrt(2*e.gust_tau);
p.envP = e;

p.launch.theta0 = pi/2 + p.launch.cant_sign*deg2rad(p.launch.cant_deg);

r = p.r; 
% We'll be adding new fields from base "r" parameter, in feet for Barrowman

r.d = r.d_in*in2ft;            % Diameter, ft
r.R_ = r.d/2;                  % Radius, ft
r.S = pi*r.d^2/4;              % Reference area, ft2
r.L = r.L_in*in2ft;            % Length, ft
r.Ln = r.Ln_in*in2ft;          % 4:1 Ogive Nosecone Length, ft
r.Cr = r.Cr_in*in2ft;          % Root chord length, ft
r.Ct = r.Ct_in*in2ft;          % Tip chord length, ft
r.sp = r.sp_in*in2ft;          % Semi-span distance, ft
r.Xr = r.Xr_in*in2ft;          % Leading edge sweep distance, ft
r.t_fin = r.t_fin_in*in2ft;      % Fin thickness, ft
r.xfinLE = r.xfinLE_in*in2ft;  % Feet from nose tip to root leading edge

% --- Barrowman potential-flow terms - Don't edit ---
r.Lf     = sqrt(r.sp^2 + (r.Xr + (r.Ct-r.Cr)/2)^2);
CNa_nose = 2;   
x_nose   = 0.466*r.Ln;  % tangent ogive
CNa_fin  = (1+r.R_/(r.sp+r.R_))*4*r.Nf*(r.sp/r.d)^2/(1+sqrt(1+(2*r.Lf/(r.Cr+r.Ct))^2));
x_fin    = r.xfinLE + r.Xr*(r.Cr+2*r.Ct)/(3*(r.Cr+r.Ct)) + (1/6)*((r.Cr+r.Ct) - r.Cr*r.Ct/(r.Cr+r.Ct));

r.CNa_pot  = CNa_nose + CNa_fin;
r.x_cp_pot = (CNa_nose*x_nose + CNa_fin*x_fin)/r.CNa_pot;   % ft from nose

% --- Crossflow and drag geometry ---
r.Aplan = r.d*r.L;   r.x_cf = 0.5*r.L;   r.Cdc = 1.2;
r.Swet_body = pi*r.d*r.L;
r.Swet_fins = 2*r.Nf*0.5*(r.Cr+r.Ct)*r.sp;   r.c_fin = (r.Cr+r.Ct)/2;
r.fb = 1 + 60/(r.L/r.d)^3 + 0.0025*(r.L/r.d);
r.Abase_ratio = 1;  

p.r = r;

c = p.chute;
c.CdS_drogue = c.Cd_drogue*pi*(c.d_drogue_in*in2ft)^2/4;
c.CdS_main   = c.Cd_main  *pi*(c.d_main_in  *in2ft)^2/4;
p.chute = c;
end