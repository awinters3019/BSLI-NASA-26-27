function rocket_viewer_full(matfile)
% rocket_viewer_full(matfile): overview + true-scale zoomed inset with alpha, CP, forces, wind
%% ---- Settings ----
EXPORT_VIDEO = false;  OVERWRITE = false;  VIDEO_FPS = 24;  VIDEO_SPEED = 1;
VIEW_HALF = 1.5;      % inset half-width, in rocket lengths
F_REF     = 50;       % lbf: forces well below this look linear, larger ones are compressed
M_REF      = 10;      % lbf*ft: moments well below this look linear, larger ones compress
ARROW_MAX = 0.8;      % longest force arrow, in rocket lengths
TICK_STEP = [5 25 50 50 50 10 5];   % grid step [ft] by phase: Pad Boost Coast Drogue MainDelay Main Landed
col_red = [0.85 0.10 0.10];  
col_blue = [0.10 0.30 0.90];
col_orange = [0.85 0.45 0.00];
col_bright_orange = [1 .6 0];

% Load paths and file data 
scripts_dir = fileparts(mfilename('fullpath'));
resdir = fullfile(fileparts(scripts_dir), 'results');
if nargin < 1
    [f, pth] = uigetfile(fullfile(resdir, 'fullres', '*.mat'), 'Pick a full-res run');
    if isequal(f, 0), return, end
    matfile = fullfile(pth, f);
end
S = load(matfile, 'F');  F = S.F;

% Get variables and geom from matfile, giving time series to be referenced
t = F.t(:);  dt = F.dt;  n = numel(t);
th_all = unwrap(F.theta(:));  alt = -F.Z(:);  Xd = F.X(:);
th_all(1) = th_all(2); % Make sure rocket appears nose-up on pad (may be obsolete now)
r = F.r;  Lr = r.L;  R = r.d/2;  Ln = r.Ln_in/12;
drogue_str = "Drogue"; main_str = "Main"; fail_str = " (failed)";
if F.drogue_fail, drogue_str = drogue_str + fail_str; end
if F.main_fail, main_str = main_str + fail_str; end
pnames = {'Pad','Boost','Coast',drogue_str,'Main delay',main_str,'Landed'};   % phase value 0-->6

% Rocket & shape outlines in body coordinates: s = distance aft of nose tip, w = sideways offset
sN = linspace(0, Ln, 15);  wN = R*(2*(sN/Ln) - (sN/Ln).^2);  % parabolic nose
bodyS = [sN, Lr, Lr, fliplr(sN)];  bodyW = [wN, R, -R, -fliplr(wN)];

sf = r.xfinLE_in/12;  Cr = r.Cr_in/12;  Ct = r.Ct_in/12;  sp = r.sp_in/12;  Xr = r.Xr_in/12;
finS = [sf, sf+Cr, sf+Xr+Ct, sf+Xr];  finW = [R, R, R+sp, R+sp];

flameS = [Lr,Lr,1.2*Lr,Lr];
flameW = [R, -R,     0,R ];

% Give maximum lengths and values for the force and moment arrows 
Fmax = max([abs(F.Fx(:)); abs(F.Fz(:)); 1]);
lenF = @(f) sign(f) * log1p(abs(f)/F_REF) / log1p(Fmax/F_REF) * ARROW_MAX * Lr;   % log-compressed length
Mz_all = F.M_thr(:) + F.M_aero(:) + F.M_chute(:);   % net applied moment [lbf*ft], nose-up positive
Mmax   = max([abs(Mz_all); 1]);
[Yap, ia] = max(alt);  Xap = Xd(ia);  tap = t(ia);  % apogee point
% Handle logic to decide the color of 
Xland = Xd(end); td_v = F.V(end); td_col = "g"; td_mark = "o";
if td_v > 20 && td_v < 150, td_col = col_bright_orange; td_mark = "hexagram";
elseif td_v >= 150, td_col = "r"; td_mark = "hexagram"; end

%% ---- Figure: overview (left) and zoomed inset (right) ----
% axO: Overview axes
fig = figure('Color','w','Position',[60 60 1350 700],'Name','Full-resolution viewer');
% set(gcf, 'Position', get(0, 'Screensize'));
axO = axes(fig,'Position',[0.04 0.17 0.28 0.75]);  hold(axO,'on');  grid(axO,'on');  box(axO,'on');
padx = 0.1*max(range(Xd), 0.2*max(alt));
xlim(axO,[min(Xd)-padx, max(Xd)+padx]);  ylim(axO,[-0.05*max(alt), 1.1*max(alt)]);  daspect(axO,[1 1 1]);
xlabel(axO,'Downrange X [ft]');  ylabel(axO,'Altitude [ft]');  title(axO,'Overview');
yline(axO,0,'k-','LineWidth',2);
% yline(axO,F.main_alt,'r--','LineWidth',1); % trying to show where main delay hits
plot(axO, Xd, alt, ':', 'Color',[.7 .7 .7]);
trailO = plot(axO,NaN,NaN,'k-','LineWidth',1.5);
dotO   = plot(axO,NaN,NaN,'o','MarkerFaceColor','r','MarkerEdgeColor','r');
plot(axO, Xap, Yap, 'p', 'MarkerSize',14, 'MarkerFaceColor','y', 'MarkerEdgeColor','k');
text(axO, Xap, Yap, sprintf('  Apogee %.0f ft', Yap), 'VerticalAlignment','bottom', 'FontWeight','bold');
plot(axO, Xland, 0, td_mark, 'MarkerSize', 14, 'MarkerFaceColor', td_col, 'MarkerEdgeColor','k');
text(axO,Xland,0, sprintf('  Impact: %.0f ft/s',td_v),"VerticalAlignment","bottom");
boxO   = plot(axO,NaN,NaN,'b-','LineWidth',1.5);          % shows what the inset is looking at

% axI: inset axes
axI = axes(fig,'Position',[0.37 0.17 0.60 0.75]);  hold(axI,'on');  grid(axI,'on');  box(axI,'on');
daspect(axI,[1 1 1]);  xlabel(axI,'Downrange X [ft]');  ylabel(axI,'Altitude [ft]');
yline(axI,0,'k-','LineWidth',3);

plot(axI, Xap, Yap, 'p', 'MarkerSize',18, 'MarkerFaceColor','y', ...
    'MarkerEdgeColor','k', 'LineWidth',1.2, 'HandleVisibility','off');
text(axI, Xap, Yap, sprintf('  Apogee: %.0f ft at t = %.1f s', Yap, tap),...
    'VerticalAlignment','bottom', 'FontWeight','bold', 'Clipping','on');

% Initialize graphics objects
hChuteLine = plot(axI,NaN,NaN,'-','LineWidth',1);
hChute     = plot(axI,NaN,NaN,'-','LineWidth',3);
body = patch(axI,NaN,NaN,col_red,'EdgeColor','k');
fin1 = patch(axI,NaN,NaN,[.3 .3 .3],'EdgeColor','k','HandleVisibility','off');
fin2 = patch(axI,NaN,NaN,[.3 .3 .3],'EdgeColor','k','HandleVisibility','off');
flame = patch(axI,NaN,NaN,col_bright_orange,'EdgeColor','k');
hV   = plot(axI,NaN,NaN,'--','Color',[.2 .6 .9],'LineWidth',1.5);
hArc = plot(axI,NaN,NaN,'-','Color',[.6 0 .6],'LineWidth',2.5);
hCG  = plot(axI,NaN,NaN,'o','MarkerSize',9,'MarkerFaceColor','w','MarkerEdgeColor','k','LineWidth',1.5);
hCP  = plot(axI,NaN,NaN,'d','MarkerSize',10,'MarkerFaceColor',col_bright_orange,'MarkerEdgeColor','k');
qFx  = quiver(axI,0,0,0,0,0,'LineWidth',3,'Color',[0.85 0 0.5],'MaxHeadSize',0.8);   % scale 0 = no autoscale
qFz  = quiver(axI,0,0,0,0,0,'LineWidth',3,'Color',[0 0.6 0.2],'MaxHeadSize',0.8);
qW   = quiver(axI,0,0,0,0,0,'LineWidth',3,'Color',[0.1 0.5 0.9],'MaxHeadSize',0.8,'HandleVisibility','off');
hW     = text(axI,0,0,'','Color',[0.1 0.5 0.9],'FontWeight','bold','HorizontalAlignment','center');
hAlpha = text(axI,0,0,'','Color',[.6 0 .6],'FontWeight','bold','FontSize',12,'HorizontalAlignment','center');
hMref  = plot(axI,NaN,NaN,':','Color',[.7 .7 .7],'LineWidth',1,'HandleVisibility','off');  % reference circle
hMarc  = plot(axI,NaN,NaN,'-','Color',col_orange,'LineWidth',3);
hMhead = patch(axI,NaN,NaN,col_orange,'EdgeColor',col_orange,'HandleVisibility','off');
hMtxt  = text(axI,0,0,'','Color',col_orange,'FontWeight','bold','HorizontalAlignment','center');
hInfo  = text(axI,0.01,0.99,'','Units','normalized','VerticalAlignment','top','FontName','FixedWidth','FontSize',10);
legend(axI,[hCG hCP qFx qFz hMarc hV hArc],{'CG','CP (effective)','F_x (body x)','F_z (body z)','net moment M', ...
       'direction of travel','angle of attack'},'Location','northeast');

%% ---- Controls ----
ar = 1;
speeds = [0.25 0.5 1 2 5];
tNow = t(1);  simT0 = t(1);  wall0 = tic;
sl  = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.04 0.08 0.93 0.03], ...
      'Min',t(1),'Max',t(end),'Value',t(1),'Callback',@(s,~) scrub(s.Value));
addlistener(sl,'ContinuousValueChange',@(s,~) scrub(s.Value));   % live scrubbing while dragging
btn = uicontrol(fig,'Style','togglebutton','String','Play','Units','normalized', ...
      'Position',[0.04 0.02 0.08 0.04],'Callback',@toggleCB);
spdMenu = uicontrol(fig,'Style','popupmenu','String',{'0.25x','0.5x','1x','2x','5x'},'Value',3, ...
      'Units','normalized','Position',[0.14 0.02 0.08 0.04],'Callback',@(~,~) rebase());
tmr = timer('ExecutionMode','fixedSpacing','Period',0.04,'BusyMode','drop', ...
            'TimerFcn',@(~,~) tick());
fig.CloseRequestFcn = @closeCB;
fig.SizeChangedFcn  = @(~,~) cacheAspect();
disableDefaultInteractivity(axI);  disableDefaultInteractivity(axO);   % removes hover/toolbar overhead
cacheAspect();
update(t(1));
if EXPORT_VIDEO, exportVideo(); end

    function update(tt)
        k  = min(max((tt - t(1))/dt, 0), n-1);       % fractional index into the uniform grid
        i0 = floor(k) + 1;  i1 = min(i0+1, n);  fr = k - floor(k);
        g  = @(v) v(i0) + fr*(v(i1) - v(i0));        % linear interpolation, O(1)
        x0 = g(Xd);  y0 = g(alt);  th = g(th_all);  xcg = g(F.CG);
        ph = F.phase(min(max(round(tt/dt)+1,1),n));     % nearest sample for the discrete phase
        drogue_cmd = F.drogue_cmd(min(max(round(tt/dt)+1,1),n));
        main_cmd   = F.main_cmd(min(max(round(tt/dt)+1,1),n));

        c  = col_blue;                                  % rocket body: always blue
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
            [px,py] = toWorld(xcp,0,x0,y0,th,xcg);  
            set(hCP,'XData',px,'YData',py);
            sm = (xcp - xcg)/r.d;           % calibers, positive = stable
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

        % burn cartoon (flame under rocket)
        if ph == 1 % boost
        [flamex,flamey] = toWorld(flameS,flameW,x0,y0,th,xcg);  
        set(flame,'XData',flamex,'YData',flamey,'FaceColor',col_bright_orange);
        else
            set(flame,'XData',NaN,'YData',NaN);
        end

        % chute cartoon, true diameter, trailing downstream of the attach point
        if drogue_cmd || main_cmd
            if main_cmd, d = F.chute.d_main_in/12;
            elseif drogue_cmd, d = F.chute.d_drogue_in/12; end
            [ax_,ay_] = toWorld(r.x_attach,0,x0,y0,th,xcg); A = [ax_; ay_];
            dv = -vh;  pv = [-dv(2); dv(1)];  C = A + 0.7*Lr*dv;
            e1 = C + (d/2)*pv;  e2 = C - (d/2)*pv;  aa = linspace(0,pi,30);
            dome = C + (d/2)*pv*cos(aa) + (d/3)*dv*sin(aa);
            set(hChuteLine,'XData',[e1(1) A(1) e2(1)],'YData',[e1(2) A(2) e2(2)],'Color',c);
            set(hChute,'XData',dome(1,:),'YData',dome(2,:),'Color',c);
        else
            set(hChuteLine,'XData',NaN,'YData',NaN);  set(hChute,'XData',NaN,'YData',NaN);
        end

        % camera follows the CG (matching the axes' pixel aspect so angles stay true)
        hw = VIEW_HALF*Lr;
        xlim(axI,[x0-hw, x0+hw]);  ylim(axI,[y0-hw*ar, y0+hw*ar]);
        st = TICK_STEP(ph+1);   % phase value runs 0..6, MATLAB indexes from 1
        xl = xlim(axI);  yl = ylim(axI);

        % Only try to set new ticks when they change
        newX = ceil(xl(1)/st)*st : st : floor(xl(2)/st)*st;
        newY = ceil(yl(1)/st)*st : st : floor(yl(2)/st)*st;
        if ~isequal(xticks(axI), newX), xticks(axI, newX); end
        if ~isequal(yticks(axI), newY), yticks(axI, newY); end

        set(boxO,'XData',x0+hw*[-1 1 1 -1 -1],'YData',y0+hw*ar*[-1 -1 1 1 -1]);
        set(trailO,'XData',Xd(1:i0),'YData',alt(1:i0));  set(dotO,'XData',x0,'YData',y0);
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
    function tick()                                  % runs every ~40 ms while playing
        if ~ishghandle(fig), return, end
        tt = simT0 + speeds(spdMenu.Value)*toc(wall0);       % sim time from the WALL CLOCK
        if tt >= t(end)
            tt = t(end);  stop(tmr);  btn.Value = 0;  btn.String = 'Play';
        end
        tNow = tt;  sl.Value = tt;  update(tt);
        drawnow limitrate;                           % lets queued clicks (Pause!) through
    end

    function toggleCB(~,~)
        if btn.Value                                 % Play
            if tNow >= t(end), tNow = t(1); end
            rebase();  btn.String = 'Pause';  start(tmr);
        else                                         % Pause
            stop(tmr);  btn.String = 'Play';
        end
    end

    function rebase()      % restart the clock from the current sim time
        simT0 = tNow;  wall0 = tic;
    end

    function scrub(val)    % any slider use pauses playback
        stop(tmr);  btn.Value = 0;  btn.String = 'Play';
        tNow = val;  update(val);
    end

    function cacheAspect()  % pixel aspect ratio, recomputed only on resize
        pp = getpixelposition(axI);  ar = pp(4)/pp(3);
    end

    function closeCB(~,~)   % without this the timer outlives the figure
        stop(tmr);  delete(tmr);  delete(fig);
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
% Ensures coordinates aligned with rocket body are placed at correct angle.
Xw = x0 + (xcg - s).*cos(th) + w.*sin(th);
Yw = y0 + (xcg - s).*sin(th) - w.*cos(th);
end