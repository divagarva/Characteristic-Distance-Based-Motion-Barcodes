% =========================================================================
% Framework 04 | Divagar Vakeesan | PhD | MATLAB Code
% =========================================================================

%% Copyright and Code Availability Notice
% Developed by Divagar Vakeesan as part of his PhD research at the
% University of Manitoba.
%
% Representative sample of Framework 04 - Intensity-Based Motion Waveforms.
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

% -------------------------------------------------------------------------
% VIDEO SELECTION + OUTPUT
% -------------------------------------------------------------------------
videoFile  = 'RIL1.mp4';
outputFile = 'FW4_Intensity_Heatmap_Output.mp4';

% =========================================================================
% OBJECT DETECTION SETTINGS (ALL AT TOP — SAME STYLE AS FW2)
% (These are the ONLY settings controlling MotionRegion extraction)
% =========================================================================
alphaBG   = 0.05;   % background update rate
thr       = 40;     % abs-diff threshold
minArea   = 3000;   % keep blobs >= this area (px)
openR     = 3;      % imopen disk radius
closeR    = 5;      % imclose disk radius
dilateR   = 5;      % dilate disk radius (for smoother region)
% =========================================================================

% -------------------------------------------------------------------------
% OTHER SETTINGS (FW4)
% -------------------------------------------------------------------------
startFrame    = 1;
endFrame      = 65;

analysisStart = 10;
analysisEnd   = 50;

alphaBarcode  = 1.0;    % |x-mu| >= alpha*sigma  (barcode threshold)

% Heatmap visualization
heatAlpha     = 0.80;         % blending strength inside MotionRegion [0..1]
useColormap   = hot(256);     % multicolor (hot)
legendW       = 220;          % legend bar width (px)
legendH       = 18;           % legend bar height (px)

% -------------------------------------------------------------------------
% VIDEO IO
% -------------------------------------------------------------------------
vr = VideoReader(videoFile);
fs = vr.FrameRate;
dt = 1/fs;

totalFrames = max(1, floor(vr.Duration * vr.FrameRate));
endFrame    = min(endFrame, totalFrames);
startFrame  = max(1, startFrame);

frameW = vr.Width;
frameH = vr.Height;

vw = VideoWriter(outputFile,'MPEG-4');
vw.FrameRate = fs;
open(vw);

% -------------------------------------------------------------------------
% HISTORY ARRAYS (signals over frames) — 5 + 5 characteristics
% -------------------------------------------------------------------------
N = endFrame;

% ---- Group-1: Intensity distribution (inside MotionRegion) ----
meanI   = NaN(N,1);
stdI    = NaN(N,1);
medianI = NaN(N,1);
entropyI= NaN(N,1);
iqrI    = NaN(N,1);

% ---- Group-2: Spatial/Tensor (inside MotionRegion) ----
meanGrad   = NaN(N,1);   % mean |∇I|
traceC     = NaN(N,1);   % Cxx + Cyy
anisoC     = NaN(N,1);   % (λ1-λ2)/(λ1+λ2)
detC       = NaN(N,1);   % det(C)
varGrad    = NaN(N,1);   % var(|∇I|)

% Aux (useful for overlay)
areaPx     = NaN(N,1);
minI       = NaN(N,1);
maxI       = NaN(N,1);

%% =========================================================================
% FIGURE 1 — VIDEO PROCESSING + HEATMAP IN MOTION AREA + SAVE VIDEO
% =========================================================================
fig1 = figure('Name','Figure 1: FW4 Intensity Heatmap (Motion Area)', ...
              'Color','w', 'Position',[100 100 frameW frameH], ...
              'MenuBar','none','ToolBar','none');

ax = axes('Parent',fig1);
set(ax,'Units','normalized','Position',[0 0 1 1]);
axis(ax,'off');

backgroundFrame = [];

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

    frame = read(vr, frameIdx);
    tsec  = (frameIdx-1)*dt;

    gray  = rgb2gray(frame);
    grayD = double(gray);   % 0..255

    if isempty(backgroundFrame)
        backgroundFrame = grayD;

        imshow(frame, 'Parent', ax); hold(ax,'on');
        % local_drawLegendBar(ax, useColormap, legendW, legendH);

        text(ax, 20, 40, sprintf('Frame: %d', frameIdx), ...
            'Color','k','FontSize',22,'FontWeight','bold', ...
            'BackgroundColor','w','Margin',4);

        % text(ax, 20, 80, sprintf('Time: %.2f s', tsec), ...
        %     'Color','k','FontSize',18,'FontWeight','bold', ...
        %     'BackgroundColor','w','Margin',4);

        hold(ax,'off'); drawnow;

        frOut = getframe(ax);
        cdata = frOut.cdata;
        cdata = imresize(cdata, [frameH frameW]);   % FIX writer mismatch
        writeVideo(vw, cdata);
        continue;
    end

    % ---- Adaptive BG update ----
    backgroundFrame = (1 - alphaBG)*backgroundFrame + alphaBG*grayD;

    % ---- Foreground mask ----
    diffIm = imabsdiff(gray, uint8(backgroundFrame));
    mask   = diffIm > thr;

    mask = imopen(mask,  strel('disk', openR));
    mask = imclose(mask, strel('disk', closeR));

    % ---- Area filter ----
    [L, nR] = bwlabel(mask);
    statsA  = regionprops(L,'Area');
    MotionRegion = false(size(mask));
    for r = 1:nR
        if statsA(r).Area >= minArea
            MotionRegion = MotionRegion | (L == r);
        end
    end
    MotionRegion = imdilate(MotionRegion, strel('disk', dilateR));

    % ---- Extract intensity pixels inside motion area ----
    pix = grayD(MotionRegion);  % double values 0..255

    if ~isempty(pix)
        areaPx(frameIdx)  = nnz(MotionRegion);

        % Group-1: distribution
        meanI(frameIdx)   = mean(pix);
        stdI(frameIdx)    = std(pix);
        medianI(frameIdx) = median(pix);

        % entropy (8-bit histogram)
        h = histcounts(uint8(pix), 0:256);
        p = h / max(sum(h),1);
        p = p(p>0);
        entropyI(frameIdx) = -sum(p .* log2(p));

        % IQR
        q25 = prctile(pix,25);
        q75 = prctile(pix,75);
        iqrI(frameIdx) = q75 - q25;

        % For overlay
        minI(frameIdx) = min(pix);
        maxI(frameIdx) = max(pix);

        % Group-2: spatial/tensor (computed on grayD)
        [Ix, Iy] = imgradientxy(grayD, 'sobel');
        gmag = hypot(Ix, Iy);

        Ix_m = Ix(MotionRegion);
        Iy_m = Iy(MotionRegion);
        g_m  = gmag(MotionRegion);

        meanGrad(frameIdx) = mean(g_m);
        varGrad(frameIdx)  = var(g_m);

        Cxx = mean(Ix_m.^2);
        Cyy = mean(Iy_m.^2);
        Cxy = mean(Ix_m.*Iy_m);

        traceC(frameIdx) = Cxx + Cyy;
        detC(frameIdx)   = Cxx*Cyy - Cxy^2;

        % eigenvalues for anisotropy
        C = [Cxx Cxy; Cxy Cyy];
        lam = eig(C);
        lam = sort(real(lam),'descend');
        l1 = lam(1); l2 = lam(2);
        anisoC(frameIdx) = (l1 - l2) / (l1 + l2 + eps);
    end

    % ---------------------------------------------------------------------
    % HEATMAP RENDER (multi-color inside MotionRegion; background white)
    % ---------------------------------------------------------------------
    I01   = grayD / 255;                      % 0..1
    idxC  = max(1, min(256, 1 + floor(I01*255)));
    heatRGB = ind2rgb(idxC, useColormap);     % frameH x frameW x 3 (double)

    outRGB = ones(frameH, frameW, 3);         % white background (double)
    mr = MotionRegion;

    % Blend heat into motion area
    for ch = 1:3
        tmp  = outRGB(:,:,ch);
        htmp = heatRGB(:,:,ch);
        tmp(mr) = (1-heatAlpha)*tmp(mr) + heatAlpha*htmp(mr);
        outRGB(:,:,ch) = tmp;
    end

    % Boundaries (black)
    boundaries = bwboundaries(MotionRegion);

    imshow(outRGB, 'Parent', ax); hold(ax,'on');

    for k = 1:numel(boundaries)
        b = boundaries{k};
        plot(ax, b(:,2), b(:,1), 'k', 'LineWidth', 2);
    end

    % Legend bar (top-left)
    local_drawLegendBar(ax, useColormap, legendW, legendH);

    % ---- TOP overlays: frame number + metrics ----
    text(ax, 20, 40, sprintf('Frame: %d', frameIdx), ...
        'Color','k','FontSize',22,'FontWeight','bold', ...
        'BackgroundColor','w','Margin',4);

    % text(ax, 20, 80, sprintf('Time: %.2f s', tsec), ...
    %     'Color','k','FontSize',18,'FontWeight','bold', ...
    %     'BackgroundColor','w','Margin',4);

    txt = sprintf([ ...
        'Area(px): %.0f\n' ...
        'Mean: %.2f   Std: %.2f   Median: %.2f\n' ...
        'Entropy: %.3f   IQR: %.2f\n' ...
        'Min: %.1f   Max: %.1f\n' ...
        'MeanGrad: %.2f   VarGrad: %.2f\n' ...
        'Trace: %.2f   Det: %.2f   Aniso: %.3f'], ...
        areaPx(frameIdx), ...
        meanI(frameIdx), stdI(frameIdx), medianI(frameIdx), ...
        entropyI(frameIdx), iqrI(frameIdx), ...
        minI(frameIdx), maxI(frameIdx), ...
        meanGrad(frameIdx), varGrad(frameIdx), ...
        traceC(frameIdx), detC(frameIdx), anisoC(frameIdx));

    text(ax, frameW-20, 40, txt, ...
        'Color','k','FontSize',14,'FontWeight','bold', ...
        'HorizontalAlignment','right','VerticalAlignment','top', ...
        'BackgroundColor','w','Margin',6);

    % Grid (same spirit as FW2)
    axis(ax,'on'); box(ax,'on'); grid(ax,'on');
    xticks(ax, 0:50:frameW);
    yticks(ax, 0:50:frameH);
    set(ax,'XColor',[0.2 0.2 0.2],'YColor',[0.2 0.2 0.2]);

    hold(ax,'off'); drawnow;

    % Save video frame (FIX size)
    frOut = getframe(ax);
    cdata = frOut.cdata;
    cdata = imresize(cdata, [frameH frameW]);
    writeVideo(vw, cdata);
end

close(vw);
disp('Done: FW4 Figure-1 heatmap video displayed and output saved.');

%% ------------------------------------------------------------------------
% ANALYSIS WINDOW (PLOTS + STATS + BARCODE ONLY FROM analysisStart:analysisEnd)
% -------------------------------------------------------------------------
analysisStart = max(1, analysisStart);
analysisEnd   = min(endFrame, analysisEnd);
plotRange     = (analysisStart:analysisEnd)';

% ===== 5 + 5 signals =====
% Group-1 (Distribution)
g1_sig  = {meanI(plotRange), stdI(plotRange), medianI(plotRange), entropyI(plotRange), iqrI(plotRange)};
g1_name = {'Mean-D','Std-D','Median-D','Entropy-D','IQR-D'};

% Group-2 (Spatial/Tensor)
g2_sig  = {meanGrad(plotRange), traceC(plotRange), anisoC(plotRange), detC(plotRange), varGrad(plotRange)};
g2_name = {'MeanGrad-S','Trace-S','Aniso-S','Det-S','VarGrad-S'};

% Colors (unique per characteristic)
cols10 = lines(10);
g1_col = {cols10(1,:), cols10(2,:), cols10(3,:), cols10(4,:), cols10(5,:)};
g2_col = {cols10(6,:), cols10(7,:), cols10(8,:), cols10(9,:), cols10(10,:)};

%% ------------------------------------------------------------------------
% FIGURE 2 — GROUP-1 (5x4)
% Column 1: Signal '-' + Envelope '--'
% Column 2: Phase
% Column 3: IF (shaded; stats from analysis window only)
% Column 4: FFT
% -------------------------------------------------------------------------
titleFS = 16; labelFS = 14; axisFS = 12; axisLW = 1.2;
xStep   = max(1, round(numel(plotRange)/10));
xMin = min(plotRange); xMax = max(plotRange);

figure('Name','Figure 2: Group-1 (Distribution) (5x4)','Color','w',...
       'Position',[60 60 1900 950]);

for r = 1:5
    yRaw = g1_sig{r};
    xRaw = plotRange;
    col  = g1_col{r};

    [y, x] = cleanSig(yRaw, xRaw);
    if numel(y) < 4, continue; end

    [~, env, ph, ifq, faxis, P1] = hilbPack(y, fs);

    subplot(5,4,(r-1)*4 + 1);
    plot(x, y,   '-',  'Color', col, 'LineWidth',1.5); hold on;
    plot(x, env, '--', 'Color', col, 'LineWidth',1.5);
    title(['Signal & Envelope (' g1_name{r} ')'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude','FontSize',labelFS);
    legend({'Signal','Envelope'},'FontSize',9,'Location','northeast');
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);
    hold off;

    subplot(5,4,(r-1)*4 + 2);
    plainPlot(x, ph, col);
    title(['Phase (' g1_name{r} ')'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

    subplot(5,4,(r-1)*4 + 3);
    freqPlotShade(x, ifq, col, plotRange);
    title(['Instantaneous Frequency (' g1_name{r} ')'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

    subplot(5,4,(r-1)*4 + 4);
    plainPlot(faxis, P1, col);
    title(['FFT (' g1_name{r} ')'],'FontSize',titleFS);
    xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
end

%% ------------------------------------------------------------------------
% FIGURE 3 — GROUP-2 (Spatial/Tensor) (5x4)
% -------------------------------------------------------------------------
figure('Name','Figure 3: Group-2 (Spatial/Tensor) (5x4)','Color','w',...
       'Position',[60 60 1900 950]);

for r = 1:5
    yRaw = g2_sig{r};
    xRaw = plotRange;
    col  = g2_col{r};

    [y, x] = cleanSig(yRaw, xRaw);
    if numel(y) < 4, continue; end

    [~, env, ph, ifq, faxis, P1] = hilbPack(y, fs);

    subplot(5,4,(r-1)*4 + 1);
    plot(x, y,   '-',  'Color', col, 'LineWidth',1.5); hold on;
    plot(x, env, '--', 'Color', col, 'LineWidth',1.5);
    title(['Signal & Envelope (' g2_name{r} ')'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude','FontSize',labelFS);
    legend({'Signal','Envelope'},'FontSize',9,'Location','northeast');
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);
    hold off;

    subplot(5,4,(r-1)*4 + 2);
    plainPlot(x, ph, col);
    title(['Phase (' g2_name{r} ')'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

    subplot(5,4,(r-1)*4 + 3);
    freqPlotShade(x, ifq, col, plotRange);
    title(['Instantaneous Frequency (' g2_name{r} ')'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

    subplot(5,4,(r-1)*4 + 4);
    plainPlot(faxis, P1, col);
    title(['FFT (' g2_name{r} ')'],'FontSize',titleFS);
    xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
end

%% ------------------------------------------------------------------------
% FIGURE 4 — 10-CHARACTERISTIC IF BARCODE (5 + 5)
% Barcode + mu/sd computed ONLY from analysis window
% -------------------------------------------------------------------------
IF = @(sig) [NaN; diff(unwrap(angle(hilbert(sig(:))))) * (fs/(2*pi))];

% Fill missing (stable Hilbert)
S = cell(10,1);
for i = 1:5
    S{i}   = fillmissing(g1_sig{i}(:),'linear','EndValues','nearest');
    S{i+5} = fillmissing(g2_sig{i}(:),'linear','EndValues','nearest');
end

fcell = cell(10,1);
for i = 1:10
    fcell{i} = IF(S{i});
end

lenAll = [numel(plotRange); cellfun(@numel, fcell(:))];  % force column
K = min(lenAll);

framesBC = plotRange(1:K);

XMat10 = NaN(10,K);
for i = 1:10
    XMat10(i,:) = fcell{i}(1:K)';
end

muVec = mean(XMat10, 2, 'omitnan');
sdVec = std(XMat10,  0, 2, 'omitnan');

psi = false(10,K);
for r = 1:10
    if ~isfinite(sdVec(r)) || sdVec(r)==0
        psi(r,:) = false;
    else
        psi(r,:) = abs(XMat10(r,:) - muVec(r)) >= alphaBarcode * sdVec(r);
    end
end
psi = double(psi);

figure('Name','Figure 4: 10-Characteristic IF Barcode (Intensity-Based)',...
       'NumberTitle','off','Position',[100 120 2000 460],'Color','w');
hold on;
set(gca,'Color',[0.94 0.94 0.94]);

barW=0.95; gap=0.04; laneH=0.90;
rectangle('Position',[0.5,0.5,K,10],'EdgeColor','k','LineWidth',3);

for c = 1:K
    xLeft = c - barW/2;
    for r = 1:10
        yBottom = r - laneH/2;
        fc = [1 1 1];
        if psi(r,c)==1, fc=[0 0 0]; end
        rectangle('Position',[xLeft+gap/2, yBottom, barW-gap, laneH],...
                  'FaceColor',fc,'EdgeColor','none');
    end
end

ylim([0.5 10.5]); xlim([0.5 K+0.5]);
set(gca,'YDir','normal');

yLabels = { ...
    'Mean_D','Std_D','Median_D','Entropy_D','IQR_D', ...
    'MeanGrad_S','Trace_S','Aniso_S','Det_S','VarGrad_S'};

set(gca,'YTick',1:10,'YTickLabel',yLabels,'FontSize',16);

set(gca,'XTick',1:K,'XTickLabel',framesBC,'FontSize',14,'TickDir','in');
xlabel('Frame Number','FontSize',18);
ylabel('Characteristics','FontSize',18);
title('Framework 04 - Running : Intensity-Based Characteristic Distance Barcode (5 Distribution + 5 Spatial)','FontSize',20);
% Separator between groups
yline(5.5,'k-','LineWidth',1.6,'Alpha',0.6);

box on; grid on;
set(gca,'XGrid','on','GridAlpha',0.12,'YGrid','off');
hold off;

disp('ALL DONE: FW4 Figure1..Figure4 generated.');





% =========================================================================
% FRAMEWORK 04 — CHARACTERISTIC NAMES
% =========================================================================

charNames = { ...
    'Mean_D'; ...
    'Std_D'; ...
    'Median_D'; ...
    'Entropy_D'; ...
    'IQR_D'; ...
    'MeanGrad_S'; ...
    'Trace_S'; ...
    'Aniso_S'; ...
    'Det_S'; ...
    'VarGrad_S' };


%% ------------------------ BARCODE STATISTICS ------------------------------

Nframes = K;                          % frames used in barcode
exceedCount = sum(psi, 2);            % number of exceedances
exceedRate  = (exceedCount./Nframes)*100;
thresholdVals = alphaBarcode .* sdVec(:);


%% =========================================================================
% CLEAN JOURNAL-STYLE PRINT
%% =========================================================================

fprintf('\n=================================================================================\n');
fprintf('Framework 04 — Instantaneous Frequency Statistical Summary\n');
fprintf('=================================================================================\n\n');

fprintf('%-3s %-18s %12s %12s %16s %10s %14s %12s\n', ...
    'ID', ...
    'Characteristic', ...
    'Mean (Hz)', ...
    'SD (Hz)', ...
    'Threshold (a*s)', ...
    'Frames', ...
    'Exceed', ...
    'E-Rate (%)');

fprintf('---------------------------------------------------------------------------------\n');

for i = 1:10
    fprintf('%-3d %-18s %12.4f %12.4f %16.4f %10d %14d %12.2f\n', ...
        i, ...
        charNames{i}, ...
        muVec(i), ...
        sdVec(i), ...
        thresholdVals(i), ...
        Nframes, ...
        exceedCount(i), ...
        exceedRate(i));
end

fprintf('=================================================================================\n\n');


%% =========================================================================
% EXPORT: Framework-04 10-Characteristic Instantaneous Frequency
%% =========================================================================

framesBC = framesBC(:);   % ensure column

IF_Table = table( ...
    framesBC, ...
    XMat10(1,:)', XMat10(2,:)', XMat10(3,:)', XMat10(4,:)', XMat10(5,:)', ...
    XMat10(6,:)', XMat10(7,:)', XMat10(8,:)', XMat10(9,:)', XMat10(10,:)', ...
    'VariableNames', { ...
    'Frame', ...
    'Mean_D','Std_D','Median_D','Entropy_D','IQR_D', ...
    'MeanGrad_S','Trace_S','Aniso_S','Det_S','VarGrad_S' });

csvIF = sprintf('FW04_IF_10chars_frames_%d_to_%d.csv', ...
                framesBC(1), framesBC(end));

writetable(IF_Table, csvIF);

disp(['Saved IF CSV: ', csvIF]);


%% =========================================================================
% EXPORT: Framework-04 10-Characteristic IF Barcode (WIDE FORMAT ONLY)
% psi: 10 x K
% framesBC: K x 1
%% =========================================================================

psiWide = psi.';            % each row = one frame

BarcodeWideTable = array2table(psiWide, ...
    'VariableNames', { ...
    'Mean_D','Std_D','Median_D','Entropy_D','IQR_D', ...
    'MeanGrad_S','Trace_S','Aniso_S','Det_S','VarGrad_S' });

BarcodeWideTable = addvars(BarcodeWideTable, framesBC, ...
    'Before', 1, 'NewVariableNames', 'Frame');

csvWide = sprintf('FW04_Barcode_10chars_frames_%d_to_%d.csv', ...
                  framesBC(1), framesBC(end));

writetable(BarcodeWideTable, csvWide);

disp(['Saved barcode CSV: ', csvWide]);

%% =========================================================================
% LOCAL HELPERS (FW2-style at bottom)
% =========================================================================
function [sig, x] = cleanSig(sig, xFrames)
    sig = sig(:);
    x   = xFrames(:);

    if sum(isfinite(sig)) >= 2
        sig = fillmissing(sig,'linear','EndValues','nearest');
    end

    v = isfinite(sig) & isfinite(x);
    sig = sig(v);
    x   = x(v);
end

function [hSig, envSig, phSig, fSig, faxis, P1] = hilbPack(sig, Fs)
    sig = sig(:);
    if numel(sig) < 4
        hSig = NaN(size(sig));
        envSig = NaN(size(sig));
        phSig  = NaN(size(sig));
        fSig   = NaN(size(sig));
        faxis  = NaN;
        P1     = NaN;
        return;
    end

    hSig   = hilbert(sig);
    envSig = abs(hSig);
    phSig  = unwrap(angle(hSig));
    fSig   = [NaN; diff(phSig) * (Fs/(2*pi))];

    N   = numel(sig);
    Y   = fft(sig, N);
    P2  = abs(Y/N);
    P1  = P2(1:floor(N/2)+1);
    if numel(P1) > 2
        P1(2:end-1) = 2*P1(2:end-1);
    end
    faxis = (0:floor(N/2))*(Fs/N);
end

function plainPlot(x, y, lineColor)
    x = x(:); y = y(:);
    v = isfinite(x) & isfinite(y);
    x = x(v); y = y(v);
    if isempty(x), return; end
    plot(x, y, '.-','Color',lineColor,'MarkerSize',12,'LineWidth',1.5);
    hold on;
end

% Stats (mu/sd) computed ONLY from statsFrames (analysis window)
function freqPlotShade(x, y, lineColor, statsFrames)
    x = x(:); y = y(:);
    v = isfinite(x) & isfinite(y);
    x = x(v); y = y(v);
    if isempty(x), return; end

    statsFrames = statsFrames(:);
    idxStats = ismember(x, statsFrames);
    yStats = y(idxStats);

    if isempty(yStats) || all(~isfinite(yStats))
        plot(x, y, '.-','Color',lineColor,'MarkerSize',12,'LineWidth',1.5);
        hold on;
        warning('freqPlotShade: No valid samples in analysisRange for stats. Stats skipped.');
        return;
    end

    mu = mean(yStats,'omitnan');
    sd = std(yStats,'omitnan');
    upper = mu + sd;
    lower = mu - sd;

    fill([x; flipud(x)], ...
         [upper*ones(size(x)); flipud(lower*ones(size(x)))], ...
         [0.8 0.8 0.8], 'FaceAlpha',0.35,'EdgeColor','none');
    hold on;

    plot(x, y, '.-','Color',lineColor,'MarkerSize',12,'LineWidth',1.5);
    yline(mu,'k-','LineWidth',1.2);
    yline(upper,'k--','LineWidth',1.2);
    yline(lower,'k--','LineWidth',1.2);

    idxRed = idxStats & ((y > upper) | (y < lower));
    if any(idxRed)
        plot(x(idxRed), y(idxRed), 'ro', 'MarkerSize',8, ...
             'MarkerFaceColor','r','LineWidth',1.2);
    end
end

function local_drawLegendBar(ax, cmap, W, H)
    % Draw a small colormap legend bar in the video frame (no colorbar object).
    % Top-left placement.
    x0 = 20; y0 = 120;

    g = repmat(linspace(1,256,W), H, 1);
    g = uint8(g);

    % Convert to RGB using cmap
    rgb = ind2rgb(g, cmap);

    image(ax, [x0 x0+W-1], [y0 y0+H-1], rgb);

    % Border + labels
    rectangle(ax, 'Position',[x0 y0 W H], 'EdgeColor','k','LineWidth',1.0);
    text(ax, x0, y0-8, 'Intensity (low \rightarrow high)', ...
        'Color','k','FontSize',12,'FontWeight','bold', ...
        'BackgroundColor','w','Margin',2, ...
        'HorizontalAlignment','left','VerticalAlignment','bottom');

    text(ax, x0, y0+H+6, '0', ...
        'Color','k','FontSize',11,'FontWeight','bold', ...
        'BackgroundColor','w','Margin',1, ...
        'HorizontalAlignment','left','VerticalAlignment','top');

    text(ax, x0+W, y0+H+6, '255', ...
        'Color','k','FontSize',11,'FontWeight','bold', ...
        'BackgroundColor','w','Margin',1, ...
        'HorizontalAlignment','right','VerticalAlignment','top');
end