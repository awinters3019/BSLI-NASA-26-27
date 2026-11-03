function rocket_viewer(runRow)
% rocket_viewer(runRow): replay one Monte Carlo run (row of M / PR)
if nargin < 1, runRow = 1; end

%% ---- Settings ----
studyName    = 'drag_sweep_pilot';    % results/<studyName>/ (folder holding mc_profiles.mat)
EXPORT_VIDEO = true;                  % true = also write an .mp4 to results/figures
OVERWRITE    = false;                 % false = skip if this run's video already exists
VIDEO_FPS    = 30;                    % frames per second in the video
VIDEO_SPEED  = 3;                     % 3 = video plays 3x faster than real flight time
ROCKET_FRAC  = 0.04;                  % rocket drawn length as a fraction of apogee (was 0.04)
col_red  = [0.85 0.10 0.10];          % rocket and chute color until main deploys
col_blue = [0.10 0.30 0.90];          % rocket and chute color once main is out

scripts_dir = fileparts(mfilename('fullpath'));
outdir = fullfile(fileparts(scripts_dir), 'results', studyName);
L = load(fullfile(outdir,'mc_profiles.mat'), 'M','PR','tgrid');
M = L.M(runRow,:);  PR = L.PR;  tg = L.tgrid(:)';

alt = double(PR.alt(runRow,:));  xd = double(PR.x(runRow,:));
th  = double(PR.theta(runRow,:)); spd = double(PR.spd(runRow,:));
v = ~isnan(alt) & ~isnan(xd) & ~isnan(th);
t = tg(v); alt = alt(v); xd = xd(v); spd = spd(v); thu = unwrap(th(v));

tph    = [M.t_boost M.t_burnout M.t_drogue M.t_maindelay M.t_main M.t_landed];
pnames = {'Pad','Boost','Coast','Drogue','Main delay','Main','Landed'};
Lr = ROCKET_FRAC*max(alt);                          % rocket drawn size (exaggerated)
body_u = [-0.5 0.3 0.5 0.3 -0.5];  body_w = [-0.07 -0.07 0 0.07 0.07];

%% ---- Figure and axes ----
fig = figure('Color','w','Position',[80 80 1200 650],'Name',sprintf('Run %d',M.run_id));
ax = axes(fig,'Position',[0.06 0.20 0.50 0.72]); hold(ax,'on'); grid(ax,'on');
xlabel(ax,'Downrange X [ft]'); ylabel(ax,'Altitude [ft]');
xlim(ax,[min(xd)-0.15*range(xd)-Lr, max(xd)+0.15*range(xd)+Lr]);
ylim(ax,[-0.05*max(alt), 1.1*max(alt)]); daspect(ax,[1 1 1]);
yline(ax,0,'k-','LineWidth',2);
plot(ax, xd, alt, ':', 'Color',[.7 .7 .7]);                      % full path, faint
trail  = plot(ax, NaN, NaN, 'k-', 'LineWidth',2);
rocket = patch(ax, NaN, NaN, col_red, 'EdgeColor','k');
chute  = plot(ax, NaN, NaN, '-', 'Color', col_red, 'LineWidth',2);

tsd = {alt,'Altitude [ft]'; spd,'Speed [ft/s]'; thu,'Pitch [rad]'};
cur = gobjects(1,3);
for k = 1:3
    a = axes(fig,'Position',[0.65 0.10+0.30*(3-k) 0.32 0.22]); hold(a,'on'); grid(a,'on');
    plot(a, t, tsd{k,1}, 'LineWidth',1.3); ylabel(a, tsd{k,2});
    for p = tph(~isnan(tph)), xline(a, p, ':r'); end             % phase transitions
    cur(k) = xline(a, t(1), 'k', 'LineWidth',1.5);
end
xlabel(a,'Time [s]');

%% ---- Controls ----
sl  = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.06 0.08 0.50 0.04], ...
      'Min',t(1),'Max',t(end),'Value',t(1),'Callback',@(s,~) update(s.Value));
btn = uicontrol(fig,'Style','togglebutton','String','Play','Units','normalized', ...
      'Position',[0.06 0.02 0.08 0.05],'Callback',@playCB);
spdMenu = uicontrol(fig,'Style','popupmenu','String',{'1x','2x','5x','10x'},'Units','normalized', ...
      'Position',[0.16 0.02 0.08 0.05]);
update(t(1));

if EXPORT_VIDEO, exportVideo(); end

    function update(tt)
        x0 = interp1(t,xd,tt);  y0 = interp1(t,alt,tt);  a0 = interp1(t,thu,tt);
        X = x0 + Lr*(body_u*cos(a0) - body_w*sin(a0));          % nose direction = (cos th, sin th)
        Y = y0 + Lr*(body_u*sin(a0) + body_w*cos(a0));
        ph = sum(tt >= tph(~isnan(tph))) + 1;                    % 1 = Pad ... 7 = Landed
        c = col_red;
        if ph >= 6, c = col_blue; end                            % main chute out: red -> blue
        set(rocket,'XData',X,'YData',Y,'FaceColor',c);
        set(trail,'XData',xd(t<=tt),'YData',alt(t<=tt));
        if ph >= 4 && ph < 7                                     % chute cartoon once drogue is out
            if ph >= 6, w = 2.5*Lr; h = 1.6*Lr; else, w = 1.0*Lr; h = 0.8*Lr; end  % main is bigger
            ang = linspace(0,pi,20);
            set(chute,'XData',x0+w*cos(ang),'YData',y0+1.2*Lr+h*sin(ang),'Color',c);
        else
            set(chute,'XData',NaN,'YData',NaN);
        end
        for kk = 1:3, cur(kk).Value = tt; end
        title(ax, sprintf('%s | t = %.1f s | alt = %.0f ft | speed = %.0f ft/s | pitch = %.0f deg', ...
              pnames{ph}, tt, y0, interp1(t,spd,tt), rad2deg(a0)));
    end

    function playCB(~,~)
        speeds = [1 2 5 10];
        while ishghandle(btn) && btn.Value
            tt = sl.Value + speeds(spdMenu.Value)*0.03;
            if tt > t(end), tt = t(1); end
            sl.Value = tt;  update(tt);
            drawnow limitrate;  pause(0.03);
        end
    end

    function exportVideo()
        figdir = fullfile(fileparts(outdir), 'figures');          % results/figures
        if ~exist(figdir,'dir'), mkdir(figdir); end
        vidFile = fullfile(figdir, sprintf('%s_run%04d.mp4', studyName, M.run_id));
        if isfile(vidFile) && ~OVERWRITE
            fprintf('Video already exists, skipping: %s\n', vidFile);
            return
        end
        vw = VideoWriter(vidFile, 'MPEG-4');
        vw.FrameRate = VIDEO_FPS;
        vw.Quality   = 90;
        open(vw);
        closer = onCleanup(@() close(vw));                        % closes the file even if an error occurs
        for tt = t(1) : VIDEO_SPEED/VIDEO_FPS : t(end)            % one iteration = one video frame
            sl.Value = tt;
            update(tt);                                           % redraw the scene at time tt
            drawnow;                                              % make MATLAB finish drawing
            writeVideo(vw, getframe(fig));                        % snapshot the figure, append it
        end
        clear closer                                              % triggers close(vw)
        fprintf('Saved video: %s\n', vidFile);
    end
end