% plot_dof_comparison.m -- 6-DOF vs 3-DOF illustration for the report
scripts_dir = fileparts(fileparts(mfilename('fullpath')));
if isempty(scripts_dir) || startsWith(scripts_dir, tempdir)
    scripts_dir = fileparts(matlab.desktop.editor.getActiveFilename);
end
parent_path = fileparts(scripts_dir);
outdir = fullfile(parent_path, 'results');
figdir = fullfile(outdir, 'figures');  if ~exist(figdir,'dir'), mkdir(figdir); end

% ---- Settings ----
R      = 2500;      % ft, cylinder radius
H      = 5500;      % ft, cylinder height
z0     = 0;         % ft, cylinder bottom. Use -H/2 for a literally centered cylinder
runRow = 1;         % which Monte Carlo run to draw (row of M / PR)
nCirc  = 120;       % cylinder smoothness

% ---- Flight path from Monte Carlo results ----
L = load(fullfile(outdir, 'mc_profiles.mat'), 'M', 'PR');
M = L.M;  PR = L.PR;
if ~(M.ok(runRow) && M.landed(runRow))             % fall back to first good run
    runRow = find(M.ok & M.landed, 1);
end
fprintf('Plotting run_id %d (wind %d mph, cant %.2f deg)\n', ...
    M.run_id(runRow), M.wind_mph(runRow), M.cant_deg(runRow));

alt = double(PR.alt(runRow,:))';
xd  = double(PR.x(runRow,:))';
v   = ~isnan(alt) & ~isnan(xd);
alt = alt(v);  xd = xd(v);                          % drop NaN tail after touchdown
yd  = zeros(size(xd));                              % 3-DOF motion stays in the y = 0 plane

% ---- Figure ----
blue = [0.15 0.40 0.90];   red = [0.85 0.10 0.10];
f = figure('Color','w','Position',[100 100 950 750]);
ax = axes(f); hold(ax,'on');

% 6-DOF "state space" cylinder (side + caps), transparent
[Xc, Yc, Zc] = cylinder(R, nCirc);
Zc = Zc*H + z0;
hCyl = surf(ax, Xc, Yc, Zc, 'FaceColor', blue, 'FaceAlpha', 0.12, 'EdgeColor', 'none');
th = linspace(0, 2*pi, nCirc+1);
for zc = [z0, z0+H]
    patch(ax, R*cos(th), R*sin(th), zc*ones(size(th)), blue, ...
        'FaceAlpha', 0.12, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    plot3(ax, R*cos(th), R*sin(th), zc*ones(size(th)), '-', ...
        'Color', blue, 'LineWidth', 1.2, 'HandleVisibility', 'off');
end

% 3-DOF plane: y = 0, spans the cylinder's diameter and height (the x-z plane)
hPlane = patch(ax, [-R R R -R], [0 0 0 0], [z0 z0 z0+H z0+H], red, ...
    'FaceAlpha', 0.22, 'EdgeColor', red, 'LineWidth', 1.5);

% Monte Carlo flight path on the plane
hPath = plot3(ax, xd, yd, alt, 'k-', 'LineWidth', 2.8);
[~, ia] = max(alt);
plot3(ax, 0, 0, alt(1), 'ko', 'MarkerFaceColor', 'g', 'MarkerSize', 8, 'HandleVisibility','off');
plot3(ax, xd(ia), 0, alt(ia), 'k^', 'MarkerFaceColor', 'y', 'MarkerSize', 9, 'HandleVisibility','off');
plot3(ax, xd(end), 0, alt(end), 'ks', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'HandleVisibility','off');
text(ax, -500, 0, alt(1) + 250, 'Launch', 'HorizontalAlignment','center', 'FontSize', 10);
text(ax, xd(ia)+600, 0, alt(ia), 'Apogee', 'HorizontalAlignment','center', 'FontSize', 10);
text(ax, xd(end)+100, 0, alt(end) + 250, 'Touchdown', 'HorizontalAlignment','center', 'FontSize', 10);

% Axes, labels, view
lim = 1.1*max(R, max(abs(xd)));
xlim(ax, [-lim lim]);  ylim(ax, [-lim lim]);  zlim(ax, [z0 - 1, max(z0+H, max(alt)) + 500]);
daspect(ax, [1 1 1]);   grid(ax,'on');  box(ax,'on');  view(ax, -38, 20);
xlabel(ax, 'Downrange drift X [ft]');
ylabel(ax, 'Crosswind Y [ft]');
zlabel(ax, 'Altitude Z [ft]');
set(ax, 'FontSize', 12, 'LineWidth', 1);
title(ax, '6-DOF vs. 3-DOF: Motion Space', 'FontSize', 15);

legend(ax, [hCyl hPlane hPath], ...
    {'6-DOF: full 3-D motion (x, y, z + roll, pitch, yaw)', ...
    '3-DOF: planar motion (x, z, pitch only)', ...
    'Example Monte Carlo flight (3-DOF)'}, ...
    'Location', 'northoutside', 'FontSize', 11, 'Box', 'off');

exportgraphics(f, fullfile(figdir, 'dof_comparison.png'), 'Resolution', 300);