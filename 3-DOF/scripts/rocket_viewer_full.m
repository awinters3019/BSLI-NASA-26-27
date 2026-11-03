function rocket_viewer_full(matfile)
% rocket_viewer_full(matfile): overview + true-scale zoomed inset with alpha, CP, forces, wind
%% ---- Settings ----
EXPORT_VIDEO = false;  OVERWRITE = false;  VIDEO_FPS = 30;  VIDEO_SPEED = 2;
VIEW_HALF = 1.5;      % inset half-width, in rocket lengths
F_REF     = 50;       % lbf: forces well below this look linear, larger ones are compressed
M_REF      = 10;      % lbf*ft: moments well below this look linear, larger ones compress
col_moment = [0.85 0.45 0.00];
ARROW_MAX = 0.8;      % longest force arrow, in rocket lengths
col_red = [0.85 0.10 0.10];  col_blue = [0.10 0.30 0.90];
TICK_STEP = [5 50 50 50 50 10 5];   % grid step [ft] by phase: Pad Boost Coast Drogue MainDelay Main Landed

% Load paths and file data 
scripts_dir = fileparts(mfilename('fullpath'));
resdir = fullfile(fileparts(scripts_dir), 'results');
if nargin < 1
    [f, pth] = uigetfile(fullfile(resdir, 'fullres', '*.mat'), 'Pick a full-res run');
    if isequal(f, 0), return, end
    matfile = fullfile(pth, f);
end
S = load(matfile, 'F');  F = S.F;


t = F.t(:);  dt = F.dt;  n = numel(t);
th_all = unwrap(F.theta(:));  alt = -F.Z(:);  Xd = F.X(:); % extract variables
th_all(1) = th_all(2); % Make sure rocket appears nose-up on pad (may be obsolete now)
r = F.r;  Lr = r.L;  R = r.d/2;  Ln = r.Ln_in/12;
pnames = {'Pad','Boost','Coast','Drogue','Main delay','Main','Landed'};   % phase value 0-->6

% Rocket outline in body coordinates: s = distance aft of nose tip, w = sideways offset
sN = linspace(0, Ln, 15);  wN = R*(2*(sN/Ln) - (sN/Ln).^2);              % parabolic nose
bodyS = [sN, Lr, Lr, fliplr(sN)];  bodyW = [wN, R, -R, -fliplr(wN)];
sf = r.xfinLE_in/12;  Cr = r.Cr_in/12;  Ct = r.Ct_in/12;  sp = r.sp_in/12;  Xr = r.Xr_in/12;
finS = [sf, sf+Cr, sf+Xr+Ct, sf+Xr];  finW = [R, R, R+sp, R+sp];

% Give maximum lengths and values for the force and moment arrows 
Fmax = max([abs(F.Fx(:)); abs(F.Fz(:)); 1]);
lenF = @(f) sign(f) * log1p(abs(f)/F_REF) / log1p(Fmax/F_REF) * ARROW_MAX * Lr;   % log-compressed length
Mz_all = F.M_thr(:) + F.M_aero(:) + F.M_chute(:);   % net applied moment [lbf*ft], nose-up positive
Mmax   = max([abs(Mz_all); 1]);
[Yap, ia] = max(alt);  Xap = Xd(ia);  tap = t(ia);  % apogee point

%% ---- Figure: overview (left) and zoomed inset (right) ----
fig = figure('Color','w','Position',[60 60 1350 700],'Name','Full-resolution viewer');
axO = axes(fig,'Position',[0.04 0.17 0.28 0.75]);  hold(axO,'on');  grid(axO,'on');  box(axO,'on');
padx = 0.1*max(range(Xd), 0.2*max(alt));
xlim(axO,[min(Xd)-padx, max(Xd)+padx]);  ylim(axO,[-0.05*max(alt), 1.1*max(alt)]);  daspect(axO,[1 1 1]);
xlabel(axO,'Downrange X [ft]');  ylabel(axO,'Altitude [ft]');  title(axO,'Overview');
yline(axO,0,'k-','LineWidth',2);
plot(axO, Xd, alt, ':', 'Color',[.7 .7 .7]);
trailO = plot(axO,NaN,NaN,'k-','LineWidth',1.5);
dotO   = plot(axO,NaN,NaN,'o','MarkerFaceColor','r','MarkerEdgeColor','r');
plot(axO, Xap, Yap, 'p', 'MarkerSize',14, 'MarkerFaceColor','y', 'MarkerEdgeColor','k');
text(axO, Xap, Yap, sprintf('  Apogee %.0f ft', Yap), 'VerticalAlignment','bottom', 'FontWeight','bold');
boxO   = plot(axO,NaN,NaN,'b-','LineWidth',1.5);          % shows what the inset is looking at

axI = axes(fig,'Position',[0.37 0.17 0.60 0.75]);  hold(axI,'on');  grid(axI,'on');  box(axI,'on');
daspect(axI,[1 1 1]);  xlabel(axI,'Downrange X [ft]');  ylabel(axI,'Altitude [ft]');
yline(axI,0,'k-','LineWidth',3);

plot(axI, Xap, Yap, 'p', 'MarkerSize',18, 'MarkerFaceColor','y', ...
    'MarkerEdgeColor','k', 'LineWidth',1.2, 'HandleVisibility','off');
text(axI, Xap, Yap, sprintf('  Apogee: %.0f ft at t = %.1f s', Yap, tap),...
    'VerticalAlignment','bottom', 'FontWeight','bold', 'Clipping','on');

hChuteLine = plot(axI,NaN,NaN,'-','LineWidth',1);
hChute     = plot(axI,NaN,NaN,'-','LineWidth',3);
body = patch(axI,NaN,NaN,col_red,'EdgeColor','k');
fin1 = patch(axI,NaN,NaN,[.3 .3 .3],'EdgeColor','k','HandleVisibility','off');
fin2 = patch(axI,NaN,NaN,[.3 .3 .3],'EdgeColor','k','HandleVisibility','off');
hV   = plot(axI,NaN,NaN,'--','Color',[.2 .6 .9],'LineWidth',1.5);
hArc = plot(axI,NaN,NaN,'-','Color',[.6 0 .6],'LineWidth',2.5);
hCG  = plot(axI,NaN,NaN,'o','MarkerSize',9,'MarkerFaceColor','w','MarkerEdgeColor','k','LineWidth',1.5);
hCP  = plot(axI,NaN,NaN,'d','MarkerSize',10,'MarkerFaceColor',[1 .6 0],'MarkerEdgeColor','k');
qFx  = quiver(axI,0,0,0,0,0,'LineWidth',3,'Color',[0.85 0 0.5],'MaxHeadSize',0.8);   % scale 0 = no autoscale
qFz  = quiver(axI,0,0,0,0,0,'LineWidth',3,'Color',[0 0.6 0.2],'MaxHeadSize',0.8);
qW   = quiver(axI,0,0,0,0,0,'LineWidth',3,'Color',[0.1 0.5 0.9],'MaxHeadSize',0.8,'HandleVisibility','off');
hW     = text(axI,0,0,'','Color',[0.1 0.5 0.9],'FontWeight','bold','HorizontalAlignment','center');
hAlpha = text(axI,0,0,'','Color',[.6 0 .6],'FontWeight','bold','FontSize',12,'HorizontalAlignment','center');
hMref  = plot(axI,NaN,NaN,':','Color',[.7 .7 .7],'LineWidth',1,'HandleVisibility','off');  % reference circle
hMarc  = plot(axI,NaN,NaN,'-','Color',col_moment,'LineWidth',3);
hMhead = patch(axI,NaN,NaN,col_moment,'EdgeColor',col_moment,'HandleVisibility','off');
hMtxt  = text(axI,0,0,'','Color',col_moment,'FontWeight','bold','HorizontalAlignment','center');
hInfo  = text(axI,0.01,0.99,'','Units','normalized','VerticalAlignment','top','FontName','FixedWidth','FontSize',10);
legend(axI,[hCG hCP qFx qFz hV hArc hMarc],{'CG','CP (effective)','F_x (body x)','F_z (body z)', ...
       'direction of travel','angle of attack','net moment M'},'Location','northeast');

%% ---- Controls ----
sl  = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.04 0.08 0.93 0.03], ...
      'Min',t(1),'Max',t(end),'Value',t(1),'Callback',@(s,~) update(s.Value));
btn = uicontrol(fig,'Style','togglebutton','String','Play/Pause','Units','normalized', ...
      'Position',[0.04 0.02 0.08 0.04],'Callback',@playCB);
spdMenu = uicontrol(fig,'Style','popupmenu','String',{'0.25x','0.5x','1x','2x','5x'},'Value',3, ...
      'Units','normalized','Position',[0.14 0.02 0.08 0.04]);
update(t(1));
if EXPORT_VIDEO, exportVideo(); end

    function update(tt)
        g  = @(v) interp1(t, v(:), tt);                 % smooth value of any signal at time tt
        x0 = g(Xd);  y0 = g(alt);  th = g(th_all);  xcg = g(F.CG);
        ph = F.phase(min(max(round(tt/dt)+1,1),n));     % nearest sample for the discrete phase
        c  = col_blue;                                  % rocket body: always blue
        cc = col_red;  if ph >= 5, cc = col_blue; end   % chute: red (drogue) -> blue (main)
        xb = [cos(th); sin(th)];                        % body x (nose) in the (X, altitude) plane
        zb = [sin(th); -cos(th)];                       % body z = nose rotated 90 deg clockwise

        % rocket at true scale
        [bx,by] = toWorld(bodyS, bodyW,x0,y0,th,xcg);  set(body,'XData',bx,'YData',by,'FaceColor',c);
        [px,py] = toWorld(finS,  finW, x0,y0,th,xcg);  set(fin1,'XData',px,'YData',py);
        [px,py] = toWorld(finS, -finW, x0,y0,th,xcg);  set(fin2,'XData',px,'YData',py);
        set(hCG,'XData',x0,'YData',y0);

        % center of pressure and stability margin
        xcp = g(F.xcp);  sm = NaN;
        if isnan(xcp), set(hCP,'XData',NaN,'YData',NaN);
        else
            [px,py] = toWorld(xcp,0,x0,y0,th,xcg);  set(hCP,'XData',px,'YData',py);
            sm = (xcp - xcg)/r.d;                       % calibers, positive = stable
        end

        % direction of travel through the air, and angle of attack
        ur = g(F.U_rel);  wr = g(F.W_rel);  V = hypot(ur,wr);  al = g(F.alpha);
        vh = [0; -1];  if V > 1, vh = (ur*xb + wr*zb)/V; end
        set(hV,'XData',x0+[0 0.9*Lr*vh(1)],'YData',y0+[0 0.9*Lr*vh(2)]);
        a  = th + linspace(0,-al,30);  ra = 0.35*Lr;    % arc from the nose axis to the travel direction
        set(hArc,'XData',x0+ra*cos(a),'YData',y0+ra*sin(a));
        am = th - al/2;
        set(hAlpha,'Position',[x0+1.45*ra*cos(am), y0+1.45*ra*sin(am), 0], ...
            'String',sprintf('\\alpha = %.1f°',rad2deg(al)));

        % net force components, drawn from the CG along the body axes
        fx = g(F.Fx);  fz = g(F.Fz);
        set(qFx,'XData',x0,'YData',y0,'UData',lenF(fx)*xb(1),'VData',lenF(fx)*xb(2));
        set(qFz,'XData',x0,'YData',y0,'UData',lenF(fz)*zb(1),'VData',lenF(fz)*zb(2));

        % wind arrow: upwind of the rocket, pointing at it; magnitude printed above
        w = g(F.wind_xe);  sg = 1;  if w < 0, sg = -1; end
        tx = x0 - sg*1.15*Lr;
        set(qW,'XData',tx,'YData',y0,'UData',sg*0.5*Lr,'VData',0);
        set(hW,'Position',[tx+sg*0.25*Lr, y0+0.12*Lr, 0],'String',sprintf('wind %.1f ft/s',abs(w)));

        % chute cartoon, true diameter, trailing downstream of the attach point
        if ph >= 3 && ph < 6
            if ph >= 5, d = F.chute.d_main_in/12; else, d = F.chute.d_drogue_in/12; end
            [ax_,ay_] = toWorld(r.x_attach,0,x0,y0,th,xcg);  A = [ax_; ay_];
            dv = -vh;  pv = [-dv(2); dv(1)];  C = A + 0.7*Lr*dv;
            e1 = C + (d/2)*pv;  e2 = C - (d/2)*pv;  aa = linspace(0,pi,30);
            dome = C + (d/2)*pv*cos(aa) + (d/3)*dv*sin(aa);
            set(hChuteLine,'XData',[e1(1) A(1) e2(1)],'YData',[e1(2) A(2) e2(2)],'Color',c);
            set(hChute,'XData',dome(1,:),'YData',dome(2,:),'Color',c);
        else
            set(hChuteLine,'XData',NaN,'YData',NaN);  set(hChute,'XData',NaN,'YData',NaN);
        end

        % camera follows the CG (matching the axes' pixel aspect so angles stay true)
        pp = getpixelposition(axI);  ar = pp(4)/pp(3);  hw = VIEW_HALF*Lr;
        xlim(axI,[x0-hw, x0+hw]);  ylim(axI,[y0-hw*ar, y0+hw*ar]);
        st = TICK_STEP(ph+1);   % phase value runs 0..6, MATLAB indexes from 1
        xl = xlim(axI);  yl = ylim(axI);
        xticks(axI, ceil(xl(1)/st)*st : st : floor(xl(2)/st)*st);   % multiples of st inside the window
        yticks(axI, ceil(yl(1)/st)*st : st : floor(yl(2)/st)*st);
        set(boxO,'XData',x0+hw*[-1 1 1 -1 -1],'YData',y0+hw*ar*[-1 -1 1 1 -1]);
        set(trailO,'XData',Xd(t<=tt),'YData',alt(t<=tt));  set(dotO,'XData',x0,'YData',y0);

        % net moment: a curved arrow in the lower-right of the window (positive = nose-up = counter-clockwise)
        mz = g(F.M_thr) + g(F.M_aero) + g(F.M_chute);
        Cm = [x0 + 0.78*hw,  y0 - 0.55*hw*ar];  rm = 0.22*Lr;           % arc center and radius
        cc_ = linspace(0, 2*pi, 60);
        set(hMref,'XData',Cm(1)+rm*cos(cc_),'YData',Cm(2)+rm*sin(cc_));
        sweep = sign(mz) * log1p(abs(mz)/M_REF)/log1p(Mmax/M_REF) * 1.5*pi;   % arc angle grows with |M|
        if abs(sweep) < 0.05
            set(hMarc,'XData',NaN,'YData',NaN);  set(hMhead,'XData',NaN,'YData',NaN);
        else
            aa = (pi/2 - sweep/2) + linspace(0, sweep, 40);                 % arc centered on the top
            set(hMarc,'XData',Cm(1)+rm*cos(aa),'YData',Cm(2)+rm*sin(aa));
            ae = aa(end);  P = Cm + rm*[cos(ae) sin(ae)];                   % arc end point
            dv = sign(sweep)*[-sin(ae) cos(ae)];                            % direction of travel at the end
            nv = [-dv(2) dv(1)];  hl = 0.07*Lr;  hb = 0.045*Lr;             % arrowhead length and half-width
            tip = P + hl*dv;  b1 = P + hb*nv;  b2 = P - hb*nv;
            set(hMhead,'XData',[tip(1) b1(1) b2(1)],'YData',[tip(2) b1(2) b2(2)]);
        end
        set(hMtxt,'Position',[Cm(1), Cm(2)-1.6*rm, 0],'String',sprintf('M = %.0f lbf·ft', mz));

        spd_tot = hypot(g(F.U), g(F.W));                % ground speed: body-axis velocity components
        % Left-hand corner numerical stats
        set(hInfo,'String',sprintf(['%s\nt      %7.2f s\nalt    %7.0f ft\nspeed  %7.1f ft/s\nMach   %7.2f\n' ...
            'alpha  %7.1f deg\nFx     %7.1f lbf\nFz     %7.1f lbf\nM      %7.1f lbf-ft\nCP-CG  %7.2f cal'], ...
        pnames{ph+1}, tt, y0, spd_tot, g(F.Mach), rad2deg(al), fx, fz, mz, sm));
        title(axI,sprintf('Zoomed view (%.0f ft across)', 2*hw));
    end

    function playCB(~,~)
        speeds = [0.25 0.5 1 2 5];
        while ishghandle(btn) && btn.Value
            tt = sl.Value + speeds(spdMenu.Value)*0.03;
            if tt > t(end), tt = t(1); end
            sl.Value = tt;  update(tt);  drawnow limitrate;  pause(0.03);
        end
    end

    function exportVideo()
        QUALITY = 90;
        figdir = fullfile(resdir,'figures');  if ~exist(figdir,'dir'), mkdir(figdir); end
        [~,base] = fileparts(matfile);
        vidFile = fullfile(figdir,[base '.mp4']);
        if isfile(vidFile) && ~OVERWRITE, fprintf('Video exists, skipping: %s\n',vidFile); return, end
        vw = VideoWriter(vidFile,'MPEG-4');  vw.FrameRate = VIDEO_FPS;  vw.Quality = QUALITY;  open(vw);
        closer = onCleanup(@() close(vw));
        for tt = t(1) : VIDEO_SPEED/VIDEO_FPS : t(end)
            sl.Value = tt;  update(tt);  drawnow;  writeVideo(vw, getframe(fig));
        end
        clear closer;  fprintf('Saved video: %s\n',vidFile);
    end
end

function [Xw,Yw] = toWorld(s, w, x0, y0, th, xcg)
% Body coordinates (s aft of the nose, w sideways) -> world (X, altitude).
% The CG sits at (x0,y0), so a point s behind the nose is (xcg - s) ahead of the CG along the nose axis.
Xw = x0 + (xcg - s).*cos(th) + w.*sin(th);
Yw = y0 + (xcg - s).*sin(th) - w.*cos(th);
end