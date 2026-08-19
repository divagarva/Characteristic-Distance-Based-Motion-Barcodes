% =========================================================================
% Framework 01 | Divagar Vakeesan | PhD | MATLAB Code
% =========================================================================

%% Copyright and Code Availability Notice
% Developed by Divagar Vakeesan as part of his PhD research at the
% University of Manitoba.
%
% Representative sample of Framework 01 - Temporally Lagged Vector Fields.
% The main processing loop and selected implementation details are omitted
% while associated research publications are under review.
%
% Full implementation is intended for release following publication.
% Copyright (c) 2026 Divagar Vakeesan. All rights reserved.
%
% Citation:
% D. Vakeesan, "Characteristic Distance-Based Barcodes Extracted from
% Vibratory Object Motion in NIR Video Frame Sequences," PhD Thesis,
% University of Manitoba, 2026.

clc; clear; close all; tic;

% 3 different Lags 1- instantaneous lag (lag1), 2 -half gait cycle lag, 3
% full gait cycle lag

%% ============================================================
%  USER PARAMETERS
%% ============================================================
videoFile        = 'RIL1.mp4';
threshold        = 20;      % strong-motion threshold on |V|
lag              = 1;       % temporal lag L
regionMode       = 'full';  % 'main' | 'full'
tauMode          = 1;       % 1=mean, 2=mean+std, 3=mean-std (post-run auto tau)

%% === Select τ thresholds based on chosen lag (φ1 … φ12) ===
switch lag
    case 1
        tauBETTI   = 0.2605;   % \phi_1  BETTI
tauUC      = 0.0217;   % \phi_2  UC
tauLAM     = 0.4581;   % \phi_3  LAM
tauIMAG    = 0.0033;   % \phi_4  IMAG
tauDIR     = 0.1273;   % \phi_5  DIR
tauROC     = 0.1217;   % \phi_6  ROC
tauDIV     = 0.1185;   % \phi_7  DIV
tauCURL    = 0.1085;   % \phi_8  CURL
tauLAPL    = 0.1012;   % \phi_9  LAPLACIAN
tauANISO   = 0.1741;   % \phi_{10}  ANISO
tauSHEAR   = 0.1110;   % \phi_{11}  SHEAR
tauENTROPY = 0.0495;   % \phi_{12}  ENTROPY

    case 11
        tauBETTI   = 0.2958;   % \phi_1  BETTI
tauUC      = 0.0296;   % \phi_2  UC
tauLAM     = 0.4212;   % \phi_3  LAM
tauIMAG    = 0.0242;   % \phi_4  IMAG
tauDIR     = 0.1827;   % \phi_5  DIR
tauROC     = 0.1640;   % \phi_6  ROC
tauDIV     = 0.1668;   % \phi_7  DIV
tauCURL    = 0.1404;   % \phi_8  CURL
tauLAPL    = 0.1395;   % \phi_9  LAPLACIAN
tauANISO   = 0.2147;   % \phi_{10}  ANISO
tauSHEAR   = 0.1534;   % \phi_{11}  SHEAR
tauENTROPY = 0.0779;   % \phi_{12}  ENTROPY

    case 22
        tauBETTI   = 0.3619;   % \phi_1  BETTI
tauUC      = 0.0347;   % \phi_2  UC
tauLAM     = 0.4180;   % \phi_3  LAM
tauIMAG    = 0.0095;   % \phi_4  IMAG
tauDIR     = 0.1996;   % \phi_5  DIR
tauROC     = 0.2180;   % \phi_6  ROC
tauDIV     = 0.2199;   % \phi_7  DIV
tauCURL    = 0.1728;   % \phi_8  CURL
tauLAPL    = 0.1806;   % \phi_9  LAPLACIAN
tauANISO   = 0.2196;   % \phi_{10}  ANISO
tauSHEAR   = 0.1996;   % \phi_{11}  SHEAR
tauENTROPY = 0.1035;   % \phi_{12}  ENTROPY

    otherwise
        error('Unsupported lag = %d.', lag);
end

%% === Visualization params (quiver) ===
vis.step       = 5;     % downsampling step
vis.lineWidth  = 3.2;   % arrow line width
vis.headSize   = 3.0;   % arrow head size
vis.gain       = 3.8;   % gain on arrow lengths

%% ============================================================
%  SETUP VIDEO
%% ============================================================
video      = VideoReader(videoFile);
frameCount = video.NumFrames;
fps        = video.FrameRate;

% === Frame range control ===
startFrame = 1;
% endFrame   = 5;
endFrame   = frameCount;

startFrame = max(1, startFrame);
endFrame   = min(frameCount, endFrame);

if endFrame - startFrame < lag
    error('Selected range [%d,%d] is too small for lag = %d.', startFrame, endFrame, lag);
end

% Preallocate frame gray + flow
G    = cell(frameCount,1);
flow = cell(frameCount,1);

opticFlow = opticalFlowFarneback;

for f = startFrame:endFrame
    F       = read(video,f);
    G{f}    = im2double(rgb2gray(F));
    flow{f} = estimateFlow(opticFlow, G{f});
end

% Number of comparisons (t, t+L)
N = (endFrame - startFrame) - lag + 1;

%% ============================================================
%  PREALLOCATE TIME SERIES
%% ============================================================
meanMagTS    = zeros(N,1);

% Distances
bettiDistTS  = zeros(N,1);
ucDistTS     = zeros(N,1);
lamMaxTS     = zeros(N,1);
imagDistTS   = zeros(N,1);
dirDistTS    = zeros(N,1);
rocDistTS    = zeros(N,1);
divDistTS    = zeros(N,1);
curlDistTS   = zeros(N,1);
anisoDistTS  = zeros(N,1);
shearDistTS  = zeros(N,1);
entDistTS    = zeros(N,1);
laplDistTS   = zeros(N,1);

% Binary φ
phi1TS       = zeros(N,1);   % BETTI
phi2TS       = zeros(N,1);   % UC
phi3TS       = zeros(N,1);   % LAM
phi4TS       = zeros(N,1);   % IMAG
phi5TS       = zeros(N,1);   % DIR
phi6TS       = zeros(N,1);   % ROC
phi7TS       = zeros(N,1);   % DIV
phi8TS       = zeros(N,1);   % CURL
phi9TS       = zeros(N,1);   % LAPLACIAN
phi10TS      = zeros(N,1);   % ANISO
phi11TS      = zeros(N,1);   % SHEAR
phi12TS      = zeros(N,1);   % ENTROPY

% Aux traces for eigen plot
lamMagTS     = zeros(N,2);
imagTS       = zeros(N,2);
imagMaxTS    = zeros(N,1);

%% ============================================================
%  OUTPUT VIDEO
%% ============================================================
[~, baseName, ~] = fileparts(videoFile);
outputFilename = sprintf('Output_%s_%dto%d_lag%d_thr%.2f_%s.mp4', ...
    baseName, startFrame, endFrame, lag, threshold, regionMode);

outputVideo = VideoWriter(outputFilename, 'MPEG-4');
open(outputVideo);

%% ============================================================
%  MAIN LOOP
%% ============================================================
    %% ============================================================
    %  MAIN LOOP REMOVED
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %% ============================================================

    idx1 = startFrame + (k - 1);
    idx2 = idx1 + lag;

    F1    = read(video, idx1);
    F2    = read(video, idx2);

    flow1 = flow{idx1};
    flow2 = flow{idx2};

    U1 = flow1.Vx;  V1 = flow1.Vy;
    U2 = flow2.Vx;  V2 = flow2.Vy;

    [H,W] = size(U1);

    % scaled for derivative-based descriptors
    U1s = U1 * fps;  V1s = V1 * fps;
    U2s = U2 * fps;  V2s = V2 * fps;

    % complex fields
    V1c = U1(:) + 1i*V1(:);
    V2c = U2(:) + 1i*V2(:);

    % Frame-level strong motion (NO overlap dependency for metrics)
    mask1 = abs(V1c) > threshold;    % frame t
    mask2 = abs(V2c) > threshold;    % frame t+L

    % "validMask" for numeric sanity (finite)
    validMask = isfinite(U1) & isfinite(V1) & isfinite(U2) & isfinite(V2);

    % store basic stat from frame t+L (strong only)
    mags2 = abs(V2c(mask2 & isfinite(V2c)));
    meanMagTS(k) = mean(mags2, 'omitnan');

    %% ============================================================
    %  Code Removed
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %
    %% ============================================================

    %% ============================================================
    %  FIGURE: 3x4 TILES + SIDE PANELS
    %% ============================================================
    fig = figure('Visible','on','Position',[100,100,1400,900]);
    mainTL = tiledlayout(fig,3,4,'TileSpacing','compact','Padding','compact');

    titleStr = sprintf('Motion Stability Lab | lag=%d | Frame %d -> %d | Region=%s', ...
        lag, idx1, idx2, regionMode);
    annotation(fig,'textbox',[0 0.965 1 0.045], ...
        'String',titleStr,'HorizontalAlignment','center','VerticalAlignment','middle', ...
        'EdgeColor','none','FontSize',18,'FontWeight','bold','Interpreter','tex');

    % Tile 01
    nexttile(mainTL,1);
    imshow(F1); axis image; axis on; grid on;
    title(sprintf('Frame ( t ) = %d', idx1), 'FontSize',20,'Interpreter','tex');

    % Tile 02
    nexttile(mainTL,2);
    imshow(F2); axis image; axis on; grid on;
    title(sprintf('Frame ( t+L ) = %d', idx2), 'FontSize',20,'Interpreter','tex');

    % Tile 03: quiver view (full/main/islands + below-threshold vectors, hide |V| < 5)
nexttile(mainTL,3); cla;

U1f = U1; V1f = V1;
U2f = U2; V2f = V2;

% ------------------------------------------------------------
% visualization cutoff: do not show vectors with magnitude < 5
% ------------------------------------------------------------
minVis = 5;

mag1 = hypot(U1f, V1f);
mag2 = hypot(U2f, V2f);

visMask_t  = mag1 >= minVis;
visMask_tp = mag2 >= minVis;

% --- strong-motion masks (already thresholded via BW1/BW2) ---
strongMask_t  = BW1;
strongMask_tp = BW2;

% --- below-threshold but visible vectors (5 <= |V| < threshold-region mask) ---
weakMask_t  = visMask_t  & (~strongMask_t);
weakMask_tp = visMask_tp & (~strongMask_tp);

% --- main / island masks ---
islandMask_t_vis  = BW1 & ~mainMask_t_vis;
islandMask_tp_vis = BW2 & ~mainMask_tp_vis;

% --- main vectors (visible only) ---
U1_main = U1f .* mainMask_t_vis  .* visMask_t;
V1_main = V1f .* mainMask_t_vis  .* visMask_t;
U2_main = U2f .* mainMask_tp_vis .* visMask_tp;
V2_main = V2f .* mainMask_tp_vis .* visMask_tp;

% --- island vectors (visible only) ---
U1_island = U1f .* islandMask_t_vis  .* visMask_t;
V1_island = V1f .* islandMask_t_vis  .* visMask_t;
U2_island = U2f .* islandMask_tp_vis .* visMask_tp;
V2_island = V2f .* islandMask_tp_vis .* visMask_tp;

% --- weak / below-threshold vectors (but >= minVis) ---
U1_weak = U1f .* weakMask_t;
V1_weak = V1f .* weakMask_t;
U2_weak = U2f .* weakMask_tp;
V2_weak = V2f .* weakMask_tp;

step = vis.step;
[XX,YY] = meshgrid(1:step:W, 1:step:H);

% scaling reference from main t+L vectors
magMain = hypot(U2_main(mainMask_tp_vis & visMask_tp), V2_main(mainMask_tp_vis & visMask_tp));
mRef    = median(magMain, 'omitnan');
if ~isfinite(mRef) || mRef <= 0
    mRef = 1;
end
qscale = vis.gain / (mRef + eps);

% downsample + scale
U1_main_vis = U1_main(1:step:end,1:step:end) * qscale;
V1_main_vis = V1_main(1:step:end,1:step:end) * qscale;
U2_main_vis = U2_main(1:step:end,1:step:end) * qscale;
V2_main_vis = V2_main(1:step:end,1:step:end) * qscale;

U1_is_vis = U1_island(1:step:end,1:step:end) * qscale;
V1_is_vis = V1_island(1:step:end,1:step:end) * qscale;
U2_is_vis = U2_island(1:step:end,1:step:end) * qscale;
V2_is_vis = V2_island(1:step:end,1:step:end) * qscale;

U1_weak_vis = U1_weak(1:step:end,1:step:end) * qscale;
V1_weak_vis = V1_weak(1:step:end,1:step:end) * qscale;
U2_weak_vis = U2_weak(1:step:end,1:step:end) * qscale;
V2_weak_vis = V2_weak(1:step:end,1:step:end) * qscale;

% colors
colMain_t      = [0 0 1];
colMain_tp     = [1 0 0];
colIsland_t    = [0.6 0.8 1.0];
colIsland_tp   = [1.0 0.6 0.6];
colWeak_t      = [0.55 0.55 0.55];
colWeak_tp     = [0.80 0.80 0.80];

hold on;

% weak vectors first (background layer)
h0 = quiver(XX,YY,U1_weak_vis,V1_weak_vis,0, ...
    'Color',colWeak_t,'LineWidth',vis.lineWidth*0.5,'MaxHeadSize',vis.headSize*0.7);
h5 = quiver(XX,YY,U2_weak_vis,V2_weak_vis,0, ...
    'Color',colWeak_tp,'LineWidth',vis.lineWidth*0.5,'MaxHeadSize',vis.headSize*0.7);

% strong main vectors
h1 = quiver(XX,YY,U1_main_vis,V1_main_vis,0, ...
    'Color',colMain_t,'LineWidth',vis.lineWidth*1.1,'MaxHeadSize',vis.headSize);
h2 = quiver(XX,YY,U2_main_vis,V2_main_vis,0, ...
    'Color',colMain_tp,'LineWidth',vis.lineWidth*1.1,'MaxHeadSize',vis.headSize);

% island vectors
h3 = quiver(XX,YY,U1_is_vis,V1_is_vis,0, ...
    'Color',colIsland_t,'LineWidth',vis.lineWidth*0.9,'MaxHeadSize',vis.headSize);
h4 = quiver(XX,YY,U2_is_vis,V2_is_vis,0, ...
    'Color',colIsland_tp,'LineWidth',vis.lineWidth*0.9,'MaxHeadSize',vis.headSize);

set(gca,'YDir','reverse');
axis image;
xlim([1 W]);
ylim([1 H]);

lgd = legend([h0 h5 h1 h2 h3 h4], ...
    {'Below thr. t','Below thr. t+L','Main VF t','Main VF t+L','Islands t','Islands t+L'}, ...
    'Location','southoutside','Orientation','horizontal','FontSize',8);
lgd.NumColumns = 3;

title(sprintf('Betti Fragmentation | D_{BETTI}=%.4f  |  \\phi_1=%d', ...
    D_BETTI, phi1TS(k)), ...
    'FontSize',14,'Interpreter','tex');

    %% Tile 04: UC polar plot
    tileAx  = nexttile(mainTL, 4);
    tilePos = tileAx.Position;
    delete(tileAx);

    shrinkFactor = 0.85;
    dx = 0.5*(1 - shrinkFactor)*tilePos(3);
    dy = 0.5*(1 - shrinkFactor)*tilePos(4);

    axUC = polaraxes('Parent', fig);
    axUC.Position = [tilePos(1)+dx, tilePos(2)+dy, tilePos(3)*shrinkFactor, tilePos(4)*shrinkFactor];
    hold(axUC,'on');

    colBlue = [0.4 0.6 1.0];
    colRed  = [1.0 0.4 0.4];

    if (isempty(theta_t_vis) || isempty(r_tn_vis)) && (isempty(theta_tp_vis) || isempty(r_tpn_vis))
        th = linspace(0,2*pi,600);
        polarplot(axUC, th, ones(size(th)), 'k-', 'LineWidth',1);
        rlim(axUC,[0 1]);
        polarplot(axUC, th, axUC.RLim(2)*ones(size(th)), 'k-', 'LineWidth',3);
        title(axUC,'No vectors for UC plot','FontSize',10,'Interpreter','tex');
    else
        if ~isempty(theta_t_vis)
            polarplot(axUC, theta_t_vis, r_tn_vis, '.', 'MarkerSize',7, 'Color',colBlue);
        end
        if ~isempty(theta_tp_vis)
            polarplot(axUC, theta_tp_vis, r_tpn_vis, '.', 'MarkerSize',7, 'Color',colRed);
        end

        th = linspace(0,2*pi,600);
        polarplot(axUC, th, ones(size(th)), 'k--', 'LineWidth',1.1);
        polarplot(axUC, th, r_mean_t_vis  * ones(size(th)), 'b--', 'LineWidth',1.6);
        polarplot(axUC, th, r_mean_tp_vis * ones(size(th)), 'r--', 'LineWidth',1.6);

        rlim(axUC,[0 1]);
        axUC.ThetaZeroLocation='right';
        axUC.ThetaDir='counterclockwise';
        polarplot(axUC, th, axUC.RLim(2)*ones(size(th)), 'k-', 'LineWidth',3);

        title(axUC, sprintf('Unit Circle | D_{UC}=%.4f  |  \\phi_2=%d', D_UC, phi2TS(k)), ...
            'FontSize',12,'Interpreter','tex');
    end

%% ============================================================
%  ROC / DIV / CURL / LAPL PANELS (2x2 GRID; FRAME-LEVEL; NO OVERLAP)
%% ============================================================
leftX   = 0.05;
leftW   = 0.43;
bottomY = 0.05;
topY    = 0.62;
hTotal  = topY - bottomY;

colGap  = 0.05;
rowGap  = 0.12;

wEach   = (leftW - colGap)/2;
hEach   = (hTotal - rowGap)/2;

x1 = leftX;
x2 = leftX + wEach + colGap;

yBot = bottomY;
yTop = bottomY + hEach + rowGap;

samplePair = @(A, mtmask, B, mtpmask) local_samplePair(A, mtmask, B, mtpmask);

% ---- font sizes ----
FS_TITLE  = 14;
FS_AXIS   = 12;
FS_LEG    = 9;
FS_TEXT   = 12;

% ============================================================
% TOP-LEFT : ROC
% ============================================================
axROC = axes('Parent', fig, 'Units','normalized', ...
             'Position',[x1, yTop, wEach, hEach]);
cla(axROC); hold(axROC,'on');

[rocX1_vals, rocX2_vals] = samplePair(dU1_dx, mt,  dU2_dx, mtp);
[rocY1_vals, rocY2_vals] = samplePair(dV1_dy, mt,  dV2_dy, mtp);

if isempty(rocX1_vals) || isempty(rocY1_vals) || isempty(rocX2_vals) || isempty(rocY2_vals)
    axis(axROC,'off');
    text(axROC,0.5,0.5,'No valid ROC samples (frame-level)', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    Lr = min([numel(rocX1_vals), numel(rocY1_vals), numel(rocX2_vals), numel(rocY2_vals)]);
    tROC = 1:Lr;

    p1 = plot(axROC, tROC, rocX1_vals(1:Lr), '-',  'LineWidth',1.3);
    p2 = plot(axROC, tROC, rocY1_vals(1:Lr), '-',  'LineWidth',1.3);
    p3 = plot(axROC, tROC, rocX2_vals(1:Lr), '--', 'LineWidth',1.3);
    p4 = plot(axROC, tROC, rocY2_vals(1:Lr), '--', 'LineWidth',1.3);

    yline(axROC,0,'k--','LineWidth',1.0);
    grid(axROC,'on');
    xlim(axROC,[1 Lr]);
    set(axROC,'FontSize',FS_AXIS);

    xlabel(axROC,'Sample Index','FontSize',FS_AXIS);
    ylabel(axROC,'Gradient Components','FontSize',FS_AXIS);

    title(axROC, { ...
        'Rate of Change'; ...
        sprintf('ROC : D_{ROC}=%.3f, \\phi_6=%d', dROC, phi6TS(k)) ...
        }, 'FontSize',FS_TITLE,'Interpreter','tex');

    legend(axROC,[p1 p2 p3 p4], ...
        {'\partial V_x/\partial x (t)','\partial V_y/\partial y (t)', ...
         '\partial V_x/\partial x (t+L)','\partial V_y/\partial y (t+L)'}, ...
        'Location','best','FontSize',FS_LEG);
end

% ============================================================
% TOP-RIGHT : DIV
% ============================================================
axDIV = axes('Parent', fig, 'Units','normalized', ...
             'Position',[x2, yTop, wEach, hEach]);
cla(axDIV); hold(axDIV,'on');

[div1_plot, div2_plot] = samplePair(div1, mt, div2, mtp);

if isempty(div1_plot) || isempty(div2_plot)
    axis(axDIV,'off');
    text(axDIV,0.5,0.5,'No valid DIV samples (frame-level)', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    Ld = min(numel(div1_plot), numel(div2_plot));
    tDV = 1:Ld;

    pD1 = plot(axDIV, tDV, div1_plot(1:Ld), '-',  'LineWidth',1.3);
    pD2 = plot(axDIV, tDV, div2_plot(1:Ld), '--', 'LineWidth',1.3);

    yline(axDIV,0,'k--','LineWidth',1.0);
    grid(axDIV,'on');
    xlim(axDIV,[1 Ld]);
    set(axDIV,'FontSize',FS_AXIS);

    xlabel(axDIV,'Sample Index','FontSize',FS_AXIS);
    ylabel(axDIV,'Divergence','FontSize',FS_AXIS);

    title(axDIV, { ...
        'Divergence'; ...
        sprintf('DIV : D_{DIV}=%.3f, \\phi_7=%d', dDIV, phi7TS(k)) ...
        }, 'FontSize',FS_TITLE,'Interpreter','tex');

    legend(axDIV,[pD1 pD2], {'DIV(t)','DIV(t+L)'}, ...
        'Location','best','FontSize',FS_LEG);
end

% ============================================================
% BOTTOM-LEFT : CURL
% ============================================================
axCURL = axes('Parent', fig, 'Units','normalized', ...
              'Position',[x1, yBot, wEach, hEach]);
cla(axCURL); hold(axCURL,'on');

[curl1_plot, curl2_plot] = samplePair(curl1, mt, curl2, mtp);

if isempty(curl1_plot) || isempty(curl2_plot)
    axis(axCURL,'off');
    text(axCURL,0.5,0.5,'No valid CURL samples (frame-level)', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    Lc = min(numel(curl1_plot), numel(curl2_plot));
    tCRL = 1:Lc;

    pC1 = plot(axCURL, tCRL, curl1_plot(1:Lc), '-',  'LineWidth',1.3);
    pC2 = plot(axCURL, tCRL, curl2_plot(1:Lc), '--', 'LineWidth',1.3);

    yline(axCURL,0,'k--','LineWidth',1.0);
    grid(axCURL,'on');
    xlim(axCURL,[1 Lc]);
    set(axCURL,'FontSize',FS_AXIS);

    xlabel(axCURL,'Sample Index','FontSize',FS_AXIS);
    ylabel(axCURL,'Curl','FontSize',FS_AXIS);

    title(axCURL, { ...
        'Curl'; ...
        sprintf('CURL : D_{CURL}=%.3f, \\phi_8=%d', dCURL, phi8TS(k)) ...
        }, 'FontSize',FS_TITLE,'Interpreter','tex');

    legend(axCURL,[pC1 pC2], {'CURL(t)','CURL(t+L)'}, ...
        'Location','best','FontSize',FS_LEG);
end

% ============================================================
% BOTTOM-RIGHT : LAPLACIAN
% ============================================================
axLAPL = axes('Parent', fig, 'Units','normalized', ...
              'Position',[x2, yBot, wEach, hEach]);
cla(axLAPL); hold(axLAPL,'on');

[lap1_plot, lap2_plot] = samplePair(lapMag1, mt, lapMag2, mtp);

if isempty(lap1_plot) || isempty(lap2_plot)
    axis(axLAPL,'off');
    text(axLAPL,0.5,0.5,'No valid LAPL samples (frame-level)', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    Ll = min(numel(lap1_plot), numel(lap2_plot));
    tLP = 1:Ll;

    pL1 = plot(axLAPL, tLP, lap1_plot(1:Ll), '-',  'LineWidth',1.3);
    pL2 = plot(axLAPL, tLP, lap2_plot(1:Ll), '--', 'LineWidth',1.3);

    yline(axLAPL,0,'k--','LineWidth',1.0);
    grid(axLAPL,'on');
    xlim(axLAPL,[1 Ll]);
    set(axLAPL,'FontSize',FS_AXIS);

    xlabel(axLAPL,'Sample Index','FontSize',FS_AXIS);
    ylabel(axLAPL,'Laplacian Magnitude','FontSize',FS_AXIS);

    title(axLAPL, { ...
        'Laplacian'; ...
        sprintf('LAPL : D_{LAPL}=%.3f, \\phi_9=%d', dLAPL, phi9TS(k)) ...
        }, 'FontSize',FS_TITLE,'Interpreter','tex');

    legend(axLAPL,[pL1 pL2], {'LAPL(t)','LAPL(t+L)'}, ...
        'Location','best','FontSize',FS_LEG);
end
    %% Tile 08: Eigen plot (φ3 & φ4)
tileAx  = nexttile(mainTL, 8);
tilePos = tileAx.Position;
delete(tileAx);

shrinkFactor = 0.80;
dx = 0.5*(1 - shrinkFactor)*tilePos(3);
dy = 0.5*(1 - shrinkFactor)*tilePos(4);

axEig = polaraxes('Parent', fig);
axEig.Position = [tilePos(1)+dx, tilePos(2)+dy, tilePos(3)*shrinkFactor, tilePos(4)*shrinkFactor];
hold(axEig,'on');

thetaC = linspace(0, 2*pi, 400);

if ~hasKrantz
    polarplot(axEig, 0, 0, '.');
    rlim(axEig, [0 1]);
    title(axEig, 'No valid eigenvalue samples', 'FontSize',10,'Interpreter','tex');
else
    polarplot(axEig, thetaC, tauLAM * ones(size(thetaC)), 'k--', 'LineWidth',1.0);

    eigCols = {'g','b'};
    for iEig = 1:numel(lambda)
        polarplot(axEig, angle(lambda(iEig)), abs(lambda(iEig)), ...
            [eigCols{iEig} 'o'], 'MarkerSize',8, 'LineWidth',1.5);
    end

    polarplot(axEig, angle(lambda(idxLamMax)), abs(lambda(idxLamMax)), 'o', ...
        'MarkerSize',6, 'MarkerFaceColor','r', 'MarkerEdgeColor','r', 'LineWidth',1.0);

    rMaxPlot = max([lamMaxVal, tauLAM]) * 1.2;
    if rMaxPlot < 1
        rMaxPlot = 1;
    end
    rlim(axEig,[0 rMaxPlot]);

    thetaO = linspace(0,2*pi,600);
    polarplot(axEig, thetaO, axEig.RLim(2)*ones(size(thetaO)), 'k-', 'LineWidth',3);

    title(axEig, { ...
        'Krantz Eigen plot'; ...
        sprintf('D_{LAM}=%.4f | \\phi_3=%d | D_{IMAG}=%.4f | \\phi_4=%d', ...
            lamMaxVal, phi3TS(k), imagDist, phi4TS(k)) ...
        }, 'FontSize',12,'Interpreter','tex');
end

    %% Tile 12: DIR polar view
    tileAx  = nexttile(mainTL, 12);
    tilePos = tileAx.Position;
    delete(tileAx);

    shrinkFactor = 0.85;
    offsetX = 0.5*(1 - shrinkFactor)*tilePos(3);
    offsetY = 0.5*(1 - shrinkFactor)*tilePos(4);

    axDIR = polaraxes('Parent', fig);
    axDIR.Position = [tilePos(1)+offsetX, tilePos(2)+offsetY, tilePos(3)*shrinkFactor, tilePos(4)*shrinkFactor];
    hold(axDIR,'on');

    if isempty(U_t_dir) && isempty(U_tp_dir)
        polarplot(axDIR,0,0,'.'); rlim(axDIR,[0 1]);
        title(axDIR,'No vectors for direction plot','FontSize',10,'Interpreter','tex');
    else
        % Normalize radii jointly
        theta_t  = atan2(V_t_dir,  U_t_dir);  r_t_raw  = hypot(U_t_dir,  V_t_dir);
        theta_tp = atan2(V_tp_dir, U_tp_dir); r_tp_raw = hypot(U_tp_dir, V_tp_dir);

        allR = [r_t_raw(:); r_tp_raw(:)];
        rMax = max([allR(:); eps]);
        r_t  = r_t_raw / rMax;
        r_tp = r_tp_raw / rMax;

        if ~isempty(theta_t)
            polarplot(axDIR, theta_t, r_t, '.', 'MarkerSize',7, 'Color',[0.4 0.6 1.0]);
        end
        if ~isempty(theta_tp)
            polarplot(axDIR, theta_tp, r_tp, '.', 'MarkerSize',7, 'Color',[1.0 0.4 0.4]);
        end

        thCircle = linspace(0,2*pi,400);
        polarplot(axDIR, thCircle, ones(size(thCircle)), 'k--', 'LineWidth',1.0);

        % Mean rays
        if ~isempty(U_t_dir)
            meanVec_t = mean(U_t_dir + 1i*V_t_dir);
            theta_mean_t = angle(meanVec_t);
            polarplot(axDIR, [theta_mean_t theta_mean_t], [0 1.15], 'b-', 'LineWidth',2.5);
        end
        if ~isempty(U_tp_dir)
            meanVec_tp = mean(U_tp_dir + 1i*V_tp_dir);
            theta_mean_tp = angle(meanVec_tp);
            polarplot(axDIR, [theta_mean_tp theta_mean_tp], [0 1.15], 'r-', 'LineWidth',2.5);
        end

        % Green/Red ARC between the two mean directions
        if ~isempty(U_t_dir) && ~isempty(U_tp_dir) && exist('theta_mean_t','var') && exist('theta_mean_tp','var')

            dtheta    = atan2(sin(theta_mean_tp - theta_mean_t), cos(theta_mean_tp - theta_mean_t));
            angleDiff = abs(dtheta);

            centerVec    = (exp(1i*theta_mean_t) + exp(1i*theta_mean_tp))/2;
            theta_center = angle(centerVec);
            halfWidth    = angleDiff/2;

            thArc = linspace(theta_center - halfWidth, theta_center + halfWidth, 200);
            thArc = mod(thArc, 2*pi);
            rArc  = 1.05 * ones(size(thArc));

            if phi5TS(k) == 1
                arcColor = [0 0.6 0];
            else
                arcColor = [0.8 0 0];
            end

            polarplot(axDIR, thArc, rArc, '-', 'LineWidth', 3, 'Color', arcColor);
        end

        rlim(axDIR,[0 1.2]);
        axDIR.ThetaZeroLocation='right';
        axDIR.ThetaDir='counterclockwise';

        thetaO = linspace(0,2*pi,600);
        polarplot(axDIR, thetaO, axDIR.RLim(2)*ones(size(thetaO)), 'k-', 'LineWidth',3);

        title(axDIR, { ...
            'Directional Plot'; ...
            sprintf('D_{DIR}=%.3f | \\phi_5=%d', D_DIR, phi5TS(k)) ...
            }, 'FontSize',12,'Interpreter','tex');
    end

   %% ============================================================
%  ANISO / SHEAR / ENT PANELS (right side)
%% ============================================================
rightX = 0.525;
rightW = 0.19;
bottomY = 0.05;
topY    = 0.62;
hTotal  = topY - bottomY;
gap     = 0.092;
hEach   = (hTotal - 2*gap) / 3;

y3 = bottomY;
y2 = bottomY + hEach + gap;
y1 = bottomY + 2*(hEach + gap);

% ---- font sizes ----
FS_TITLE = 14;
FS_AXIS  = 12;
FS_LEG   = 10;
FS_TEXT  = 12;

% ============================================================
% ---- ANISO ----
% ============================================================
axA = axes('Parent', fig, 'Units','normalized', ...
           'Position',[rightX, y1, rightW, hEach]);
cla(axA);

if ~hasANISO
    axis(axA,'off');
    text(axA,0.5,0.5,'No ANISO samples', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    hold(axA,'on');

    bar(axA, 1, A_t,  0.6, 'FaceColor', [0 0.45 0.85]);
    bar(axA, 2, A_tp, 0.6, 'FaceColor', [0.85 0 0]);

    set(axA,'XTick',[1 2],'XTickLabel',{'t','t+L'},'FontSize',FS_AXIS);
    ylim(axA,[0 1]);
    grid(axA,'on');

    ylabel(axA,'Anisotropy A','FontSize',FS_AXIS);

    title(axA, { ...
        'Anisotropy'; ...
        sprintf('D_{ANISO}=%.4f | \\phi_{10}=%d', D_ANISO, phi10TS(k)) ...
        }, 'Interpreter','tex','FontSize',FS_TITLE);
end

% ============================================================
% ---- SHEAR ----
% ============================================================
axS = axes('Parent', fig, 'Units','normalized', ...
           'Position',[rightX, y2, rightW, hEach]);
cla(axS);

if ~hasSHEAR
    axis(axS,'off');
    text(axS,0.5,0.5,'No SHEAR samples', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    maxShear = max([shear1_vals(:); shear2_vals(:)]);
    if maxShear <= 0, maxShear = 1; end

    edgesShear   = linspace(0, maxShear, 20);
    h1s          = histcounts(shear1_vals, edgesShear, 'Normalization','probability');
    h2s          = histcounts(shear2_vals, edgesShear, 'Normalization','probability');
    centersShear = (edgesShear(1:end-1) + edgesShear(2:end))/2;

    hold(axS,'on');

    p1 = plot(axS, centersShear, h1s, '-o',  'LineWidth',1.4, 'Color',[0 0.45 0.85]);
    p2 = plot(axS, centersShear, h2s, '--x', 'LineWidth',1.4, 'Color',[0.85 0 0]);

    grid(axS,'on');
    set(axS,'FontSize',FS_AXIS);

    xlabel(axS,'Shear Magnitude','FontSize',FS_AXIS);
    ylabel(axS,'P(shear)','FontSize',FS_AXIS);

    legend(axS,[p1 p2], {'t','t+L'}, ...
        'Location','best','FontSize',FS_LEG);

    title(axS, { ...
        'Shear'; ...
        sprintf('D_{SHEAR}=%.3f | \\phi_{11}=%d', D_SHEAR, phi11TS(k)) ...
        }, 'Interpreter','tex','FontSize',FS_TITLE);
end

% ============================================================
% ---- ENTROPY ----
% ============================================================
axE = axes('Parent', fig, 'Units','normalized', ...
           'Position',[rightX, y3, rightW, hEach]);
cla(axE);

if ~hasENT || isempty(theta1_ent) || isempty(theta2_ent)
    axis(axE,'off');
    text(axE,0.5,0.5,'No ENT samples', ...
        'HorizontalAlignment','center','FontSize',FS_TEXT);
else
    nBins = 18;
    edges = linspace(0, 2*pi, nBins+1);

    h1_plot = histcounts(theta1_ent, edges);
    h2_plot = histcounts(theta2_ent, edges);

    p1_plot = h1_plot / max(sum(h1_plot),1);
    p2_plot = h2_plot / max(sum(h2_plot),1);

    centers = (edges(1:end-1) + edges(2:end))/2;

    hold(axE,'on');

    p1h = plot(axE, centers, p1_plot, '-o',  'LineWidth',1.4, 'Color',[0 0.45 0.85]);
    p2h = plot(axE, centers, p2_plot, '--x', 'LineWidth',1.4, 'Color',[0.85 0 0]);

    xlim(axE,[0 2*pi]);
    xticks(axE,[0 pi/2 pi 3*pi/2 2*pi]);
    xticklabels(axE,{'0','\pi/2','\pi','3\pi/2','2\pi'});

    grid(axE,'on');
    set(axE,'FontSize',FS_AXIS);

    xlabel(axE,'Direction \theta','Interpreter','tex','FontSize',FS_AXIS);
    ylabel(axE,'P(\theta)','Interpreter','tex','FontSize',FS_AXIS);

    legend(axE,[p1h p2h], {'t','t+L'}, ...
        'Location','best','FontSize',FS_LEG);

    title(axE, { ...
        'Entropy'; ...
        sprintf('D_{ENT}=%.3f | \\phi_{12}=%d', D_ENT, phi12TS(k)) ...
        }, 'Interpreter','tex','FontSize',FS_TITLE);
end

    %% Uniform outline/grid (skip polar)
    allAxes = findall(fig,'Type','axes');
    outlineLW = 1; gridLW = 0.1;

    for ax = reshape(allAxes,1,[])
        if isa(ax,'matlab.graphics.axis.PolarAxes')
            continue;
        end
        ax.Box='on';
        ax.LineWidth = outlineLW;
        ax.XGrid='on'; ax.YGrid='on';
        ax.GridLineStyle='-';
        ax.Layer='top';
        ax.GridColorMode='manual';
        ax.GridColor = [0.75 0.75 0.75];
        ax.GridAlpha = gridLW / outlineLW;
    end

    frameCap = getframe(fig);
    writeVideo(outputVideo, frameCap);
    close(fig);
end

%% ============================================================
%  FINISH VIDEO
%% ============================================================
close(outputVideo);
disp(['Saved stability video as ', outputFilename]);
toc;

%% ============================================================
%  POST-PROCESSING: DUAL OUTPUTS
%  1) MANUAL thresholds  (from switch lag)
%  2) AUTO thresholds    (from tauMode)
%% ============================================================

%% ============================================================
%  SAVE ORIGINAL / MANUAL THRESHOLDS
%% ============================================================
tauManual = struct();
tauManual.BETTI     = tauBETTI;
tauManual.UC        = tauUC;
tauManual.LAM       = tauLAM;
tauManual.IMAG      = tauIMAG;
tauManual.DIR       = tauDIR;
tauManual.ROC       = tauROC;
tauManual.DIV       = tauDIV;
tauManual.CURL      = tauCURL;
tauManual.LAPLACIAN = tauLAPL;
tauManual.ANISO     = tauANISO;
tauManual.SHEAR     = tauSHEAR;
tauManual.ENTROPY   = tauENTROPY;

%% ============================================================
%  DISTANCE STRUCT
%% ============================================================
D = struct();
D.BETTI     = bettiDistTS;
D.UC        = ucDistTS;
D.LAM       = lamMaxTS;
D.IMAG      = imagDistTS;
D.DIR       = dirDistTS;
D.ROC       = rocDistTS;
D.DIV       = divDistTS;
D.CURL      = curlDistTS;
D.LAPLACIAN = laplDistTS;
D.ANISO     = anisoDistTS;
D.SHEAR     = shearDistTS;
D.ENTROPY   = entDistTS;

charNames = { ...
    'BETTI'; ...
    'UC'; ...
    'LAM'; ...
    'IMAG'; ...
    'DIR'; ...
    'ROC'; ...
    'DIV'; ...
    'CURL'; ...
    'LAPLACIAN'; ...
    'ANISO'; ...
    'SHEAR'; ...
    'ENTROPY' };

distCell = { ...
    bettiDistTS; ...
    ucDistTS; ...
    lamMaxTS; ...
    imagDistTS; ...
    dirDistTS; ...
    rocDistTS; ...
    divDistTS; ...
    curlDistTS; ...
    laplDistTS; ...
    anisoDistTS; ...
    shearDistTS; ...
    entDistTS };

%% ============================================================
%  AUTO THRESHOLD COMPUTATION
%% ============================================================
tauAuto = struct();
stats   = struct();

muVec      = zeros(12,1);
sdVec      = zeros(12,1);
tauAutoVec = zeros(12,1);
nVec       = zeros(12,1);

for i = 1:numel(charNames)
    nm = charNames{i};
    x  = D.(nm);
    x  = x(isfinite(x));

    if isempty(x)
        tauAuto.(nm) = NaN;
        stats.(nm).mean = NaN;
        stats.(nm).std  = NaN;
        stats.(nm).n    = 0;

        muVec(i)      = NaN;
        sdVec(i)      = NaN;
        tauAutoVec(i) = NaN;
        nVec(i)       = 0;
        continue;
    end

    mu = mean(x,'omitnan');
    sd = std(x,'omitnan');

    switch tauMode
        case 1
            tauAuto.(nm) = mu;
        case 2
            tauAuto.(nm) = mu + sd;
        case 3
            tauAuto.(nm) = mu - sd;
        otherwise
            error('tauMode must be 1, 2, or 3');
    end

    stats.(nm).mean = mu;
    stats.(nm).std  = sd;
    stats.(nm).n    = numel(x);

    muVec(i)      = mu;
    sdVec(i)      = sd;
    tauAutoVec(i) = tauAuto.(nm);
    nVec(i)       = numel(x);
end

tauManualVec = [ ...
    tauManual.BETTI; ...
    tauManual.UC; ...
    tauManual.LAM; ...
    tauManual.IMAG; ...
    tauManual.DIR; ...
    tauManual.ROC; ...
    tauManual.DIV; ...
    tauManual.CURL; ...
    tauManual.LAPLACIAN; ...
    tauManual.ANISO; ...
    tauManual.SHEAR; ...
    tauManual.ENTROPY ];

%% ============================================================
%  PRINT THRESHOLD SETS
%% ============================================================
fprintf('\n============================================================\n');
fprintf('MANUAL THRESHOLDS (given values)\n');
fprintf('============================================================\n');
for i = 1:12
    fprintf('%-12s : %.4f\n', charNames{i}, tauManualVec(i));
end

fprintf('\n============================================================\n');
fprintf('AUTO THRESHOLDS (tauMode = %d)\n', tauMode);
fprintf('============================================================\n');
for i = 1:12
    fprintf('%-12s : %.4f\n', charNames{i}, tauAutoVec(i));
end
fprintf('============================================================\n\n');

%% ============================================================
%  GENERATE BOTH OUTPUT MODES
%% ============================================================
generate_mode_outputs( ...
    'MANUAL', tauManualVec, distCell, charNames, muVec, sdVec, ...
    lag, startFrame, endFrame, baseName);

generate_mode_outputs( ...
    'AUTO', tauAutoVec, distCell, charNames, muVec, sdVec, ...
    lag, startFrame, endFrame, baseName);

%% ============================================================
%  HELPER FUNCTION: GENERATE ALL OUTPUTS FOR ONE MODE
%% ============================================================
function generate_mode_outputs(modeName, tauVec, distCell, charNames, muVec, sdVec, lag, startFrame, endFrame, baseName)

    nChar = numel(charNames);
    phiCell    = cell(nChar,1);
    phiPadCell = cell(nChar,1);

    exceedCount = zeros(nChar,1);
    exceedRate  = zeros(nChar,1);
    nVec        = zeros(nChar,1);

    minVals = zeros(nChar,1);
    maxVals = zeros(nChar,1);
    muPlusSigma  = muVec + sdVec;
    muMinusSigma = muVec - sdVec;

    for i = 1:nChar
        Dcur = distCell{i};
        Dcur = Dcur(:);

        phiCell{i}    = double(Dcur >= tauVec(i));
        phiPadCell{i} = [nan(lag,1); phiCell{i}];

        x = Dcur(isfinite(Dcur));
        nVec(i) = numel(x);

        if isempty(x)
            exceedCount(i) = 0;
            exceedRate(i)  = NaN;
            minVals(i)     = NaN;
            maxVals(i)     = NaN;
        else
            exceedCount(i) = sum(x >= tauVec(i));
            exceedRate(i)  = 100 * exceedCount(i) / max(numel(x),1);
            minVals(i)     = min(x,[],'omitnan');
            maxVals(i)     = max(x,[],'omitnan');
        end
    end

    %% ========================================================
    %  JOURNAL-STYLE PRINT
    %% ========================================================
    fprintf('\n==============================================================================================================\n');
    fprintf('Framework 01 — %s Threshold Statistical Summary\n', modeName);
    fprintf('==============================================================================================================\n\n');

    fprintf('%-3s %-16s %12s %12s %14s %10s %12s %12s\n', ...
        'ID', 'Characteristic', 'Mean', 'SD', 'Threshold', 'Frames', 'Exceed', 'E-Rate (%)');
    fprintf('--------------------------------------------------------------------------------------------------------------\n');

    for i = 1:nChar
        fprintf('%-3d %-16s %12.4f %12.4f %14.4f %10d %12d %12.2f\n', ...
            i, charNames{i}, muVec(i), sdVec(i), tauVec(i), nVec(i), exceedCount(i), exceedRate(i));
    end

    fprintf('==============================================================================================================\n\n');

    %% ========================================================
    %  SUMMARY TABLE + CSV
    %% ========================================================
    SummaryTable = table( ...
        (1:nChar)', ...
        string(charNames), ...
        muVec, ...
        sdVec, ...
        tauVec, ...
        nVec, ...
        exceedCount, ...
        exceedRate, ...
        'VariableNames', {'ID','Characteristic','Mean','SD','Threshold','Frames','Exceed','ExceedRatePct'});

    summaryCsvName = sprintf('Generated_Summary_%s_%s_lag%d.csv', modeName, baseName, lag);
    writetable(SummaryTable, summaryCsvName);
    disp(['Saved summary CSV as ', summaryCsvName]);

    %% ========================================================
    %  TIME-SERIES PLOT PACK
    %% ========================================================
    phiTitles = { ...
        '\phi_1  BETTI', ...
        '\phi_2  UC', ...
        '\phi_3  LAM', ...
        '\phi_4  IMAG', ...
        '\phi_5  DIR', ...
        '\phi_6  ROC', ...
        '\phi_7  DIV', ...
        '\phi_8  CURL', ...
        '\phi_9  LAPLACIAN', ...
        '\phi_{10} ANISO', ...
        '\phi_{11} SHEAR', ...
        '\phi_{12} ENTROPY'};

    phiYLabels = { ...
        'D_{BETTI}(k)', ...
        'D_{UC}(k)', ...
        'D_{LAM}(k)', ...
        'D_{IMAG}(k)', ...
        'D_{DIR}(k)', ...
        'D_{ROC}(k)', ...
        'D_{DIV}(k)', ...
        'D_{CURL}(k)', ...
        'D_{LAPL}(k)', ...
        'D_{ANISO}(k)', ...
        'D_{SHEAR}(k)', ...
        'D_{ENT}(k)'};

    phiDistPlot = cell(nChar,1);
    phiYLim     = cell(nChar,1);

    for i = 1:nChar
        Dtmp = distCell{i};
        phiDistPlot{i} = [nan(1,lag), Dtmp(:)'];

        Dfinite = Dtmp(isfinite(Dtmp));
        if isempty(Dfinite)
            phiYLim{i} = [0 1];
        else
            ymax = max(Dfinite);
            phiYLim{i} = [0, max(1.1*ymax, 0.01)];
        end
    end

    figure('Name',sprintf('12 Distance Time-Series (%s)', modeName), ...
           'NumberTitle','off', 'Color','w', 'Position',[80 60 1900 980]);

    tiledlayout(3,4,'TileSpacing','compact','Padding','compact');

    FS_TIT = 18;
    FS_AX  = 14;
    FS_LAB = 18;

    for i = 1:nChar
        nexttile;
        Dvalid = distCell{i};
        Dplot  = phiDistPlot{i};

        Np = numel(Dplot);
        x  = startFrame : (startFrame + Np - 1);

        mu = mean(Dvalid,'omitnan');
        sd = std(Dvalid,'omitnan');
        tauThis = tauVec(i);

        hold on;

        for kk = 1:(Np-1)
            x1 = x(kk); x2 = x(kk+1);
            y1 = Dplot(kk); y2 = Dplot(kk+1);

            if ~isfinite(y1) || ~isfinite(y2)
                continue;
            end

            if (y1 >= mu) && (y2 >= mu)
                line([x1 x2],[y1 y2],'Color','r','LineWidth',1.6);
            elseif (y1 < mu) && (y2 < mu)
                line([x1 x2],[y1 y2],'Color','b','LineWidth',1.6);
            else
                t = (mu - y1) / (y2 - y1);
                t = max(0,min(1,t));
                xc = x1 + t*(x2 - x1);
                yc = mu;

                if y1 < mu
                    line([x1 xc],[y1 yc],'Color','b','LineWidth',1.6);
                else
                    line([x1 xc],[y1 yc],'Color','r','LineWidth',1.6);
                end

                if y2 < mu
                    line([xc x2],[yc y2],'Color','b','LineWidth',1.6);
                else
                    line([xc x2],[yc y2],'Color','r','LineWidth',1.6);
                end
            end
        end

        isFinite = isfinite(Dplot);
        isAbove  = (Dplot >= mu) & isFinite;
        isBelow  = (Dplot <  mu) & isFinite;

        plot(x(isAbove), Dplot(isAbove), 'o', 'MarkerSize',6, ...
             'MarkerFaceColor','r','MarkerEdgeColor','r');
        plot(x(isBelow), Dplot(isBelow), 'o', 'MarkerSize',6, ...
             'MarkerFaceColor','b','MarkerEdgeColor','b');

        yl = phiYLim{i};
        if ~isempty(yl) && all(isfinite(yl)) && numel(yl)==2
            ylim(yl);
        end
        yl = ylim;

        xValid = x((lag+1):end);
        yLow   = mu - sd;
        yHigh  = mu + sd;
        yLowC  = max(yLow, yl(1));
        yHighC = min(yHigh, yl(2));

        if yHighC > yLowC && ~isempty(xValid)
            fill([xValid fliplr(xValid)], ...
                 [yHighC*ones(size(xValid)) fliplr(yLowC*ones(size(xValid)))], ...
                 [0.85 0.85 0.85], 'EdgeColor','none','FaceAlpha',0.35);
            uistack(findobj(gca,'Type','line'),'top');
        end

        yline(mu,      'k--', 'LineWidth',1.6);
        yline(yLow,    'k:',  'LineWidth',1.4);
        yline(yHigh,   'k:',  'LineWidth',1.4);
        yline(tauThis, 'm-.', 'LineWidth',1.8);

        grid on;
        set(gca,'FontSize',FS_AX,'LineWidth',1.0);
        xlabel('Frame Index (k)','FontSize',FS_LAB);
        ylabel(phiYLabels{i},'Interpreter','tex','FontSize',FS_LAB);
        xlim([startFrame endFrame]);

        title(sprintf('%s | %s | \\tau=%.3f, \\mu=%.3f, \\sigma=%.3f', ...
              phiTitles{i}, modeName, tauThis, mu, sd), ...
              'Interpreter','tex','FontSize',FS_TIT);
    end

    %% ========================================================
    %  BARCODE PREP
    %% ========================================================
    Npad = numel(phiPadCell{1});
    frameIdx = (startFrame : startFrame + Npad - 1).';

    barcodeTable = table( ...
        frameIdx, ...
        phiPadCell{1}, ...
        phiPadCell{2}, ...
        phiPadCell{3}, ...
        phiPadCell{4}, ...
        phiPadCell{5}, ...
        phiPadCell{6}, ...
        phiPadCell{7}, ...
        phiPadCell{8}, ...
        phiPadCell{9}, ...
        phiPadCell{10}, ...
        phiPadCell{11}, ...
        phiPadCell{12}, ...
        'VariableNames', { ...
            'k', 'phi_1','phi_2','phi_3','phi_4','phi_5','phi_6', ...
            'phi_7','phi_8','phi_9','phi_10','phi_11','phi_12' } );

    csvName = sprintf('Generated_Barcode_%s_%s_lag%d.csv', modeName, baseName, lag);
    writetable(barcodeTable, csvName);
    disp(['Saved barcode CSV as ', csvName]);

    %% ========================================================
    %  BARCODE PLOT
    %% ========================================================
    figure('Name',sprintf('Characteristic Barcode (%s)', modeName), ...
        'NumberTitle','off', 'Position',[100 100 1800 520], 'Color','w');
    hold on;
    set(gca,'Color',[0.94 0.94 0.94]);

    phiMat = [ ...
        phiPadCell{1}, ...
        phiPadCell{2}, ...
        phiPadCell{3}, ...
        phiPadCell{4}, ...
        phiPadCell{5}, ...
        phiPadCell{6}, ...
        phiPadCell{7}, ...
        phiPadCell{8}, ...
        phiPadCell{9}, ...
        phiPadCell{10}, ...
        phiPadCell{11}, ...
        phiPadCell{12}]';

    [nRows, nCols] = size(phiMat);

    barWidth = 0.95;
    gap      = 0.03;
    laneH    = 0.95;

    outerX = 0.5; outerY = 0.5; outerW = nCols; outerH = nRows;
    rectangle('Position',[outerX, outerY, outerW, outerH], ...
              'EdgeColor',[0 0 0], 'LineWidth',4, 'FaceColor','none');

    for k = 1:nCols
        xLeft = k - barWidth/2;
        for r = 1:nRows
            yCenter = r;
            yBottom = yCenter - laneH/2;

            if isnan(phiMat(r,k))
                faceColor = [0.80 0.80 0.80];
            elseif phiMat(r,k) == 1
                faceColor = [0 0 0];
            else
                faceColor = [1 1 1];
            end

            rectangle('Position',[xLeft + gap/2, yBottom, barWidth - gap, laneH], ...
                      'FaceColor', faceColor, 'EdgeColor','none');
        end
    end

    set(gca,'YDir','normal');
    set(gca,'YTick',1:12, ...
        'YTickLabel', { ...
        '$\mathbf{\phi_1}\ \mathbf{BETTI}$', ...
        '$\mathbf{\phi_2}\ \mathbf{UC}$', ...
        '$\mathbf{\phi_3}\ \mathbf{LAM}$', ...
        '$\mathbf{\phi_4}\ \mathbf{IMAG}$', ...
        '$\mathbf{\phi_5}\ \mathbf{DIR}$', ...
        '$\mathbf{\phi_6}\ \mathbf{ROC}$', ...
        '$\mathbf{\phi_7}\ \mathbf{DIV}$', ...
        '$\mathbf{\phi_8}\ \mathbf{CURL}$', ...
        '$\mathbf{\phi_9}\ \mathbf{LAPL}$', ...
        '$\mathbf{\phi_{10}}\ \mathbf{ANISO}$', ...
        '$\mathbf{\phi_{11}}\ \mathbf{SHEAR}$', ...
        '$\mathbf{\phi_{12}}\ \mathbf{ENT}$'}, ...
        'TickLabelInterpreter','latex', ...
        'FontSize',15);

    tickStep = 10;
    xt = 1:tickStep:nCols;

    if xt(end) ~= nCols
        if (nCols - xt(end)) <= round(tickStep/2)
            xt(end) = nCols;
        else
            xt = [xt nCols];
        end
    end

    xtlbl_vals = startFrame + xt - 1;

    xtlbl = arrayfun(@(kk) sprintf('$\\mathbf{%d}$', kk), xtlbl_vals, ...
                     'UniformOutput', false);

    set(gca,'XTick', xt, ...
            'XTickLabel', xtlbl, ...
            'TickLabelInterpreter','latex', ...
            'TickDir','in');

    xlim([0.5, nCols + 0.5]);
    ylim([0.6, nRows + 0.4]);

    xlabel('Frame Index (k)','FontSize',30);
    ylabel('Characteristic Functions','FontSize',25);
    title({ ...
        sprintf('Framework 01 - Running : Temporally Lag Based %s Threshold Characteristic Distance Barcode (Lag = %d)', modeName, lag), ...
        'Characteristic Stability Assessment (1 = D_i \geq \tau_i [UnStable], 0 = D_i < \tau_i [Stable], blank = undefined)'}, ...
        'FontSize',30,'Interpreter','tex');

    ax = gca;
    ax.Position = [0.07 0.22 0.90 0.60];
    box on;
    set(gca,'XGrid','on','GridAlpha',0.12,'YGrid','off');

    %% ========================================================
    %  FULL STATS CSV
    %% ========================================================
    numOnes  = zeros(nChar,1);
    numZeros = zeros(nChar,1);

    for i = 1:nChar
        numOnes(i)  = sum(phiCell{i}==1);
        numZeros(i) = sum(phiCell{i}==0);
    end

    statTable = table( ...
        string(charNames), tauVec, muVec, sdVec, muPlusSigma, muMinusSigma, ...
        minVals, maxVals, numOnes, numZeros, ...
        'VariableNames', {'Characteristic','Tau','Mean','StdDev','MeanPlusStd', ...
                          'MeanMinusStd','MinValue','MaxValue','NumOnes','NumZeros'});

    statCsvName = sprintf('Generated_Stats_%s_%s_lag%d.csv', modeName, baseName, lag);
    writetable(statTable, statCsvName);
    disp(['Saved statistics CSV as ', statCsvName]);

end

%% ============================================================
%  HELPERS
%% ============================================================
function [mainMask, islandMask, D_BETTI, bettiCuts] = bettiFragmentation(BW)
    CC = bwconncomp(BW, 8);
    numRegions = CC.NumObjects;

    if numRegions > 0
        regionSizes = cellfun(@numel, CC.PixelIdxList);
        [~, largestIdx] = max(regionSizes);

        mainMask = false(size(BW));
        mainMask(CC.PixelIdxList{largestIdx}) = true;

        islandMask = BW & ~mainMask;
    else
        mainMask = false(size(BW));
        islandMask = false(size(BW));
        numRegions = 0;
    end

    bettiCuts = max(numRegions - 1, 0);

    A_main    = nnz(mainMask);
    A_islands = nnz(islandMask);
    A_total   = A_main + A_islands;

    if A_total == 0
        D_BETTI = 0;
    else
        D_BETTI = A_islands / A_total;
    end
end

function [a, b] = local_samplePair(A, mt, B, mtp)
    a = A(mt);  a = a(isfinite(a));
    b = B(mtp); b = b(isfinite(b));

    if isempty(a) || isempty(b)
        a = []; b = [];
        return;
    end

    n  = min(numel(a), numel(b));
    ia = round(linspace(1, numel(a), n));
    ib = round(linspace(1, numel(b), n));

    a = a(ia);
    b = b(ib);
end