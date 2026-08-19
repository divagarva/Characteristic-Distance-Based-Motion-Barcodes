% =========================================================================
% Framework 03 | Divagar Vakeesan | PhD | MATLAB Code
% =========================================================================

%% Copyright and Code Availability Notice
% Developed by Divagar Vakeesan as part of his PhD research at the
% University of Manitoba.
%
% Representative sample of Framework 03 - Geometric Shape-Based Motion
% Waveforms. The main processing loop and selected implementation details
% are omitted while associated research publications are under review.
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
outputFile = 'Processed_Video_Output_FW3.mp4';

% =========================================================================
% OBJECT DETECTION SETTINGS (ALL AT TOP — SAME STYLE AS FW2)
% =========================================================================
alphaBG   = 0.05;   % background update rate
thr       = 40;     % abs-diff threshold
minArea   = 3000;   % keep blobs >= this area (px)
openR     = 3;      % imopen disk radius
closeR    = 5;      % imclose disk radius
dilateR   = 5;      % dilate disk radius for expandedMask / bbox
% =========================================================================

% -------------------------------------------------------------------------
% OTHER SETTINGS (FW3 specific)
% -------------------------------------------------------------------------
startFrame    = 1;      % 1-based indexing (robust with read())
endFrame      = 65;     % will clamp to total frames

analysisStart = 10;
analysisEnd   = 50;

alphaBarcode  = 1.0;    % |x-mu| >= alpha*sigma

% -------------------------------------------------------------------------
% VIDEO IO
% -------------------------------------------------------------------------
vr = VideoReader(videoFile);
fs = vr.FrameRate;

totalFrames = max(1, floor(vr.Duration * vr.FrameRate));
endFrame    = min(endFrame, totalFrames);
startFrame  = max(1, startFrame);

frameW = vr.Width;
frameH = vr.Height;

vw = VideoWriter(outputFile, 'MPEG-4');
vw.FrameRate = fs;
open(vw);

% -------------------------------------------------------------------------
% HISTORY ARRAYS (allocate up to endFrame)
% -------------------------------------------------------------------------
N = endFrame;

% Perimeter (circumference-like)
motionRegionCirc = NaN(N,1);
hullCirc         = NaN(N,1);
rectCirc         = NaN(N,1);
circleCirc       = NaN(N,1);
triCirc          = NaN(N,1);
ellipseCirc      = NaN(N,1);

% Area
motionRegionArea = NaN(N,1);
hullArea         = NaN(N,1);
rectArea         = NaN(N,1);
circleArea       = NaN(N,1);
triArea          = NaN(N,1);
ellipseArea      = NaN(N,1);

% Bounding box dims (optional)
rectW            = NaN(N,1);
rectH            = NaN(N,1);

% -------------------------------------------------------------------------
% FIGURE 1 — VIDEO PROCESSING + SAVE OUTPUT VIDEO (FW2 STYLE)
% -------------------------------------------------------------------------
figure('Name','Figure 1: FW3 Video Output','Color','w',...
       'Position',[100 100 frameW frameH]);

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
    gray  = rgb2gray(frame);

    if isempty(backgroundFrame)
        backgroundFrame = double(gray);
        imshow(frame); hold on;

        % ---- TOP overlay (frame number only; metrics unavailable first frame) ----
        text(20, 40, sprintf('Frame: %d', frameIdx), ...
            'Color','k','FontSize',22,'FontWeight','bold', ...
            'BackgroundColor','w','Margin',4);

        hold off; drawnow;

        frameForVideo = getframe(gca);
        writeVideo(vw, frameForVideo.cdata);
        continue;
    end

    % ---- Adaptive BG update ----
    backgroundFrame = (1 - alphaBG)*backgroundFrame + alphaBG*double(gray);

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

    expandedMask = imdilate(MotionRegion, strel('disk', dilateR));

    % ---- WHITE background + RED motion (same visual concept as FW2) ----
    redCh   = uint8(MotionRegion) * 255;
    greenCh = frame(:,:,2);
    blueCh  = frame(:,:,3);

    redCh(~MotionRegion)   = 255;
    greenCh(~MotionRegion) = 255;
    blueCh(~MotionRegion)  = 255;

    highlightedFrame = cat(3, redCh, greenCh, blueCh);

    % ---- Extract boundaries (original) ----
    boundaries = bwboundaries(MotionRegion);

    % Flatten boundaries into a single cloud of points for hull/circle/tri/ellipse
    allBoundaryPoints = [];
    for k = 1:numel(boundaries)
        allBoundaryPoints = [allBoundaryPoints; boundaries{k}]; %#ok<AGROW>
    end

    % ---- Metrics: MotionRegion (perimeter + area) ----
    if ~isempty(boundaries)
        motionRegionCirc(frameIdx) = sum(cellfun(@(b) size(b,1), boundaries)); % (index-count proxy)
        motionRegionArea(frameIdx) = bwarea(MotionRegion);
    end

    % ---- Compute hull + bbox + centroid from expandedMask ----
    props = regionprops(expandedMask,'Centroid','BoundingBox');
    haveProps = ~isempty(props);

    if haveProps
        centroid = props(1).Centroid;
        rectBB   = props(1).BoundingBox;

        rectW(frameIdx) = rectBB(3);
        rectH(frameIdx) = rectBB(4);

        rectCirc(frameIdx) = 2*(rectBB(3) + rectBB(4));
        rectArea(frameIdx) = rectBB(3) * rectBB(4);
    end

    % ---- Convex Hull (PolygonRegion) + circle + triangle + ellipse ----
    PolygonRegion = [];
    circleCenter = [NaN NaN]; radius = NaN;

    if size(allBoundaryPoints,1) >= 3

        % Convex hull in (x,y) = (col,row)
        hullIdx = convhull(allBoundaryPoints(:,2), allBoundaryPoints(:,1));
        PolygonRegion = allBoundaryPoints(hullIdx,:);

        hullCirc(frameIdx) = sum(sqrt(sum(diff(PolygonRegion).^2,2)));
        hullArea(frameIdx) = polyarea(PolygonRegion(:,2), PolygonRegion(:,1));

        % Smallest enclosing circle (Welzl) in x=col, y=row
        [circleCenter, radius] = welzl_min_circle(allBoundaryPoints(:,2), allBoundaryPoints(:,1));
        circleCirc(frameIdx) = 2*pi*radius;
        circleArea(frameIdx) = pi*radius^2;

        % Triangle from 3 farthest points
        distances = pdist2(allBoundaryPoints, allBoundaryPoints);
        [~, idxMax] = max(distances(:));
        [p1, p2] = ind2sub(size(distances), idxMax);

        remaining = setdiff(1:size(allBoundaryPoints,1), [p1 p2]);
        maxA = 0; p3 = remaining(1);

        for rr = remaining
            A = allBoundaryPoints([p1 p2 rr],:);
            a = polyarea(A(:,1), A(:,2));
            if a > maxA
                maxA = a;
                p3 = rr;
            end
        end

        triPts = [allBoundaryPoints(p1,:); allBoundaryPoints(p2,:); allBoundaryPoints(p3,:)];
        triCirc(frameIdx) = sum(sqrt(sum(diff([triPts; triPts(1,:)]).^2,2)));
        triArea(frameIdx) = maxA;

        % Ellipse from Line-A + max perpendicular reach (Line-B)
        pointA = allBoundaryPoints(p1,:);
        pointB = allBoundaryPoints(p2,:);

        dirVec  = (pointB - pointA) / max(norm(pointB - pointA), eps);
        perpVec = [-dirVec(2), dirVec(1)];

        maxDist = 0;

        for t = 0:0.01:1
            curPt = (1-t)*pointA + t*pointB;

            for sgn = [-1, 1]
                extPt = curPt + sgn*1000*perpVec;

                [xI, yI] = polyxpoly([curPt(2), extPt(2)], ...
                                     [curPt(1), extPt(1)], ...
                                     allBoundaryPoints(:,2), allBoundaryPoints(:,1));

                if ~isempty(xI)
                    ip = [yI(1), xI(1)];
                    d  = norm(ip - curPt);
                    if d > maxDist
                        maxDist = d;
                    end
                end
            end
        end

        ellipseCenter = (pointA + pointB)/2;
        majorLen = norm(pointB - pointA);
        minorLen = maxDist * 2;

        angleRot = atan2(pointB(1)-pointA(1), pointB(2)-pointA(2));

        a = majorLen/2; b = minorLen/2;
        ellipseArea(frameIdx) = pi*a*b;
        ellipseCirc(frameIdx) = pi*(3*(a+b) - sqrt((3*a+b)*(a+3*b))); % Ramanujan approx

        theta = linspace(0, 2*pi, 100);
        xE = a*cos(theta);
        yE = b*sin(theta);

        xRot = xE*cos(angleRot) - yE*sin(angleRot) + ellipseCenter(2);
        yRot = xE*sin(angleRot) + yE*cos(angleRot) + ellipseCenter(1);

    else
        triPts = [];
        xRot = []; yRot = [];
    end

    % ---------------------------------------------------------------------
    % DISPLAY (overlay + grid + save frame)
    % ---------------------------------------------------------------------
    imshow(highlightedFrame); hold on;

    % Original boundaries (black)
    for k = 1:numel(boundaries)
        b = boundaries{k};
        plot(b(:,2), b(:,1), 'k', 'LineWidth', 2);
    end

    if ~isempty(PolygonRegion)
        plot(PolygonRegion(:,2), PolygonRegion(:,1), 'Color',[0 0 1], 'LineWidth', 2); % hull blue
    end

    if haveProps
        rectangle('Position', rectBB, 'EdgeColor',[0 0.5 0], 'LineWidth', 2); % bbox green
        plot(centroid(1), centroid(2), 'bo', 'MarkerSize',10, 'MarkerFaceColor','none');
    end

    % Lines centroid->hull vertices (cyan dashed)
    if haveProps && ~isempty(PolygonRegion)
        for i = 1:size(PolygonRegion,1)
            plot([centroid(1), PolygonRegion(i,2)], ...
                 [centroid(2), PolygonRegion(i,1)], ...
                 'c--','LineWidth',1);
        end
    end

    % Smallest circle
    if isfinite(radius)
        th = linspace(0, 2*pi, 120);
        xC = circleCenter(1) + radius*cos(th);
        yC = circleCenter(2) + radius*sin(th);
        plot(xC, yC, 'Color',[0.3010 0.7450 0.9330], 'LineWidth', 2);
    end

    % Triangle
    if ~isempty(triPts)
        plot(triPts([1:end 1],2), triPts([1:end 1],1), ...
            'Color',[0.9290 0.6940 0.1250], 'LineWidth', 2);
    end

    % Ellipse
    if ~isempty(xRot)
        plot(xRot, yRot, 'm-', 'LineWidth', 2);
    end

    % ---------------- TOP TEXT OVERLAYS (Frame + Perim/Area for each shape) ----------------
    % Frame number
    text(20, 40, sprintf('Frame: %d', frameIdx), ...
        'Color','k','FontSize',22,'FontWeight','bold', ...
        'BackgroundColor','w','Margin',4);

    % One compact multi-line block
    % (Uses NaN-safe formatting: NaN prints as NaN)
    txt = sprintf([ ...
        'Motion   P=%.2f  A=%.2f\n' ...
        'Hull     P=%.2f  A=%.2f\n' ...
        'Rect     P=%.2f  A=%.2f\n' ...
        'Circle   P=%.2f  A=%.2f\n' ...
        'Tri      P=%.2f  A=%.2f\n' ...
        'Ellipse  P=%.2f  A=%.2f'], ...
        motionRegionCirc(frameIdx), motionRegionArea(frameIdx), ...
        hullCirc(frameIdx),         hullArea(frameIdx), ...
        rectCirc(frameIdx),         rectArea(frameIdx), ...
        circleCirc(frameIdx),       circleArea(frameIdx), ...
        triCirc(frameIdx),          triArea(frameIdx), ...
        ellipseCirc(frameIdx),      ellipseArea(frameIdx));

    % Place at top-right with small margin
    text(frameW-20, 40, txt, ...
        'Color','k','FontSize',16,'FontWeight','bold', ...
        'HorizontalAlignment','right','VerticalAlignment','top', ...
        'BackgroundColor','w','Margin',6);

    % Grid
    axis on; box on; grid on;
    xticks(0:50:frameW); yticks(0:50:frameH);

    hold off; drawnow;

    % Save frame
    frameForVideo = getframe(gca);
    writeVideo(vw, frameForVideo.cdata);
end

close(vw);
disp('Done: FW3 Figure-1 video displayed and output saved.');

% -------------------------------------------------------------------------
% ANALYSIS WINDOW (like FW2)
% -------------------------------------------------------------------------
analysisStart = max(1, analysisStart);
analysisEnd   = min(endFrame, analysisEnd);
frameRange    = analysisStart:analysisEnd;

frames = frameRange(:);
Fs     = fs;

% -------------------------------------------------------------------------
% FIGURE 2 — PERIMETER (Signal | Envelope | Phase | IF | FFT) — 6 shapes
% NOTE CHANGE: FIRST COLUMN -> Signal '-' and Envelope '--'
% -------------------------------------------------------------------------
titleFS = 18; labelFS = 16; axisFS = 14; axisLW = 1.5;
xStep   = max(1, round(numel(frameRange)/10));

c1 = [1 0 0];                 % Motion
c2 = [0 0 1];                 % Hull
c3 = [0 0.5 0];               % Rect
c4 = [0.3010 0.7450 0.9330];  % Circle
c5 = [0.9290 0.6940 0.1250];  % Tri
c6 = [1 0 1];                 % Ellipse

shapeNames  = {'Motion','Hull','Rect','Circle','Tri','Ellipse'};
shapeColors = {c1,c2,c3,c4,c5,c6};

perimSignals = { ...
    motionRegionCirc(frameRange), ...
    hullCirc(frameRange), ...
    rectCirc(frameRange), ...
    circleCirc(frameRange), ...
    triCirc(frameRange), ...
    ellipseCirc(frameRange)};

figure('Name','Figure 2: Perimeter Hilbert + FFT (6 shapes)','Color','w');

for r = 1:6
    x = frames;
    y = perimSignals{r}(:);

    [y, x] = cleanSig(y, x);
    if numel(y) < 4, continue; end

    [~, env, ph, ifq, fax, P1] = hilbPack(y, Fs);

    % ---- Column 1: Signal + Envelope (requested style) ----
    subplot(6,4,(r-1)*4 + 1);
    plot(x, y,   '-',  'Color', shapeColors{r}, 'LineWidth',1.6); hold on; % Signal '-'
    plot(x, env, '--', 'Color', shapeColors{r}, 'LineWidth',1.6); hold off; % Envelope '--'
    title(['Signal & Envelope (' shapeNames{r} ' - P)'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
    legend({'Signal','Envelope'},'FontSize',9,'Location','northeast');
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
    xticks(min(frames):xStep:max(frames));

    % ---- Column 2: Phase ----
    subplot(6,4,(r-1)*4 + 2);
    plainPlot(x, ph, shapeColors{r});
    title(['Phase (' shapeNames{r} ' - P)'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
    xticks(min(frames):xStep:max(frames));

    % ---- Column 3: Inst. Frequency (shaded) ----
    subplot(6,4,(r-1)*4 + 3);
    freqPlotShade(x, ifq, shapeColors{r}, frames);
    title(['Inst. Freq (' shapeNames{r} ' - P)'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Freq (Hz)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
    xticks(min(frames):xStep:max(frames));

    % ---- Column 4: FFT ----
    subplot(6,4,(r-1)*4 + 4);
    plainPlot(fax, P1, shapeColors{r});
    title(['FFT (' shapeNames{r} ' - P)'],'FontSize',titleFS);
    xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P1(f)|','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
end

% -------------------------------------------------------------------------
% FIGURE 3 — AREA (Signal | Envelope | Phase | IF | FFT) — 6 shapes
% NOTE CHANGE: FIRST COLUMN -> Signal '-' and Envelope '--'
% -------------------------------------------------------------------------
areaSignals = { ...
    motionRegionArea(frameRange), ...
    hullArea(frameRange), ...
    rectArea(frameRange), ...
    circleArea(frameRange), ...
    triArea(frameRange), ...
    ellipseArea(frameRange)};

figure('Name','Figure 3: Area Hilbert + FFT (6 shapes)','Color','w');

for r = 1:6
    x = frames;
    y = areaSignals{r}(:);

    [y, x] = cleanSig(y, x);
    if numel(y) < 4, continue; end

    [~, env, ph, ifq, fax, P1] = hilbPack(y, Fs);

    % ---- Column 1: Signal + Envelope (requested style) ----
    subplot(6,4,(r-1)*4 + 1);
    plot(x, y,   '-',  'Color', shapeColors{r}, 'LineWidth',1.6); hold on;
    plot(x, env, '--', 'Color', shapeColors{r}, 'LineWidth',1.6); hold off;
    title(['Signal & Envelope (' shapeNames{r} ' - A)'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
    legend({'Signal','Envelope'},'FontSize',9,'Location','northeast');
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
    xticks(min(frames):xStep:max(frames));

    subplot(6,4,(r-1)*4 + 2);
    plainPlot(x, ph, shapeColors{r});
    title(['Phase (' shapeNames{r} ' - A)'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
    xticks(min(frames):xStep:max(frames));

    subplot(6,4,(r-1)*4 + 3);
    freqPlotShade(x, ifq, shapeColors{r}, frames);
    title(['Inst. Freq (' shapeNames{r} ' - A)'],'FontSize',titleFS);
    xlabel('Frame Number','FontSize',labelFS); ylabel('Freq (Hz)','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
    xticks(min(frames):xStep:max(frames));

    subplot(6,4,(r-1)*4 + 4);
    plainPlot(fax, P1, shapeColors{r});
    title(['FFT (' shapeNames{r} ' - A)'],'FontSize',titleFS);
    xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P1(f)|','FontSize',labelFS);
    grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);
end

% -------------------------------------------------------------------------
% FIGURE 4 — 12-CHARACTERISTIC IF BARCODE (6 Perimeter + 6 Area)
% (Computed ONLY from analysis window)
% -------------------------------------------------------------------------
IF = @(sig) local_instfreq(sig(:), Fs);

IF_perim = cell(6,1);
IF_area  = cell(6,1);

for i = 1:6
    IF_perim{i} = IF(perimSignals{i});
    IF_area{i}  = IF(areaSignals{i});
end

% Align common length K
K = numel(frames);
for i=1:6
    K = min(K, numel(IF_perim{i}));
    K = min(K, numel(IF_area{i}));
end

framesBC = frames(1:K);

XMat12 = nan(12,K);
for i=1:6
    XMat12(i,:)   = IF_perim{i}(1:K)';
    XMat12(i+6,:) = IF_area{i}(1:K)';
end

muVec = mean(XMat12, 2, 'omitnan');
sdVec = std(XMat12,  0, 2, 'omitnan');

psi = false(12,K);
for r = 1:12
    if ~isfinite(sdVec(r)) || sdVec(r)==0
        psi(r,:) = false;
    else
        psi(r,:) = abs(XMat12(r,:) - muVec(r)) >= alphaBarcode * sdVec(r);
    end
end
psi = double(psi);

figure('Name','Figure 4: 12-Characteristic IF Barcode (6P+6A)',...
       'NumberTitle','off','Position',[80 120 2000 500],'Color','w');
hold on; set(gca,'Color',[0.94 0.94 0.94]);

barW=0.95; gap=0.04; laneH=0.90;

rectangle('Position',[0.5,0.5,K,12],'EdgeColor','k','LineWidth',3);

for c = 1:K
    xLeft = c - barW/2;
    for r = 1:12
        yBottom = r - laneH/2;
        fc = [1 1 1];
        if psi(r,c)==1, fc=[0 0 0]; end
        rectangle('Position',[xLeft+gap/2, yBottom, barW-gap, laneH],...
                  'FaceColor',fc,'EdgeColor','none');
    end
end

ylim([0.5 12.5]); xlim([0.5 K+0.5]);
set(gca,'YDir','normal');

yLabels = { ...
    'Motion_{P}','Hull_{P}','Rect_{P}','Circle_{P}','Tri_{P}','Ellipse_{P}', ...
    'Motion_{A}','Hull_{A}','Rect_{A}','Circle_{A}','Tri_{A}','Ellipse_{A}'};

set(gca,'YTick',1:12,'YTickLabel',yLabels,'FontSize',16);
set(gca,'XTick',1:K,'XTickLabel',framesBC,'FontSize',14,'TickDir','in');

xlabel('Frame Number','FontSize',18);
ylabel('Characteristics','FontSize',18);
title('Framework 03 - Running : Geometric Shape Based Characteristic Distance Barcode (6 Perimeter + 6 Area)','FontSize',24);

yline(6.5,'k-','LineWidth',1.6,'Alpha',0.6);
box on; grid on;
set(gca,'XGrid','on','GridAlpha',0.12,'YGrid','off');
hold off;

disp('ALL DONE: FW3 Figure1..Figure4 generated.');


% =========================================================================
% FRAMEWORK 03 — CHARACTERISTIC NAMES
% =========================================================================

charNames = { ...
    'Motion_P'; ...
    'Hull_P'; ...
    'Rect_P'; ...
    'Circle_P'; ...
    'Tri_P'; ...
    'Ellipse_P'; ...
    'Motion_A'; ...
    'Hull_A'; ...
    'Rect_A'; ...
    'Circle_A'; ...
    'Tri_A'; ...
    'Ellipse_A' };


%% ------------------------ BARCODE STATISTICS ------------------------------

Nframes = K;                          % frames used in barcode
exceedCount = sum(psi, 2);            % number of exceedances
exceedRate  = (exceedCount./Nframes)*100;
thresholdVals = alphaBarcode .* sdVec(:);



%% =========================================================================
% CLEAN JOURNAL-STYLE PRINT
%% =========================================================================

fprintf('\n=================================================================================\n');
fprintf('Framework 03 — Instantaneous Frequency Statistical Summary\n');
fprintf('=================================================================================\n\n');

fprintf('%-3s %-16s %12s %12s %16s %10s %14s %12s\n', ...
    'ID', ...
    'Characteristic', ...
    'Mean (Hz)', ...
    'SD (Hz)', ...
    'Threshold (a*s)', ...
    'Frames', ...
    'Exceed', ...
    'E-Rate (%)');

fprintf('---------------------------------------------------------------------------------\n');

for i = 1:12
    fprintf('%-3d %-16s %12.4f %12.4f %16.4f %10d %14d %12.2f\n', ...
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
% EXPORT: Framework-03 12-Characteristic Instantaneous Frequency
%% =========================================================================

IF_Table = table( ...
    framesBC, ...
    XMat12(1,:)', XMat12(2,:)', XMat12(3,:)', XMat12(4,:)', XMat12(5,:)', XMat12(6,:)', ...
    XMat12(7,:)', XMat12(8,:)', XMat12(9,:)', XMat12(10,:)', XMat12(11,:)', XMat12(12,:)', ...
    'VariableNames', { ...
    'Frame', ...
    'Motion_P','Hull_P','Rect_P','Circle_P','Tri_P','Ellipse_P', ...
    'Motion_A','Hull_A','Rect_A','Circle_A','Tri_A','Ellipse_A' });

csvIF = sprintf('FW03_IF_12chars_frames_%d_to_%d.csv', ...
                framesBC(1), framesBC(end));

writetable(IF_Table, csvIF);

disp(['Saved IF CSV: ', csvIF]);

%% =========================================================================
% EXPORT: Framework-03 12-Characteristic IF Barcode (WIDE FORMAT ONLY)
% psi: 12 x K
% framesBC: K x 1
%% =========================================================================

framesBC = framesBC(:);     % ensure column

psiWide = psi.';            % each row = one frame

BarcodeWideTable = array2table(psiWide, ...
    'VariableNames', { ...
    'Motion_P','Hull_P','Rect_P','Circle_P','Tri_P','Ellipse_P', ...
    'Motion_A','Hull_A','Rect_A','Circle_A','Tri_A','Ellipse_A' });

BarcodeWideTable = addvars(BarcodeWideTable, framesBC, ...
    'Before', 1, 'NewVariableNames', 'Frame');

csvWide = sprintf('FW03_Barcode_12chars_frames_%d_to_%d.csv', ...
                  framesBC(1), framesBC(end));

writetable(BarcodeWideTable, csvWide);

disp(['Saved barcode CSV: ', csvWide]);







%% =========================================================================
% LOCAL HELPERS (same “FW2 style”: all helpers at bottom)
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
        hSig = NaN(size(sig)); envSig = NaN(size(sig));
        phSig = NaN(size(sig)); fSig = NaN(size(sig));
        faxis = NaN; P1 = NaN; return;
    end

    hSig   = hilbert(sig);
    envSig = abs(hSig);
    phSig  = unwrap(angle(hSig));
    fSig   = [NaN; diff(phSig) * (Fs/(2*pi))];

    N = numel(sig);
    Y = fft(sig, N);
    P2 = abs(Y/N);
    P1 = P2(1:floor(N/2)+1);
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
    plot(x, y, '.-', 'Color', lineColor, 'MarkerSize', 12, 'LineWidth', 1.5);
    hold on;
end

function freqPlotShade(x, y, lineColor, statsFrames)
    x = x(:); y = y(:);
    v = isfinite(x) & isfinite(y);
    x = x(v); y = y(v);
    if isempty(x), return; end

    statsFrames = statsFrames(:);
    idxStats = ismember(x, statsFrames);
    yStats = y(idxStats);

    if isempty(yStats) || all(~isfinite(yStats))
        plot(x, y, '.-', 'Color', lineColor, 'MarkerSize', 12, 'LineWidth', 1.5);
        hold on;
        warning('freqPlotShade: No valid samples in analysis window for stats. Skipped.');
        return;
    end

    mu = mean(yStats,'omitnan');
    sd = std(yStats,'omitnan');
    upper = mu + sd;
    lower = mu - sd;

    fill([x; flipud(x)], ...
         [upper*ones(size(x)); flipud(lower*ones(size(x)))], ...
         [0.8 0.8 0.8], 'FaceAlpha', 0.35, 'EdgeColor', 'none');
    hold on;

    plot(x, y, '.-', 'Color', lineColor, 'MarkerSize', 12, 'LineWidth', 1.5);
    yline(mu,    'k-',  'LineWidth', 1.2);
    yline(upper, 'k--', 'LineWidth', 1.2);
    yline(lower, 'k--', 'LineWidth', 1.2);

    idxRed = idxStats & ((y > upper) | (y < lower));
    if any(idxRed)
        plot(x(idxRed), y(idxRed), 'ro', 'MarkerSize', 8, ...
            'MarkerFaceColor','r', 'LineWidth', 1.2);
    end
end

function f = local_instfreq(y, Fs)
    y = y(:);
    if numel(y) < 4
        f = NaN(size(y)); return;
    end

    v = isfinite(y);
    if nnz(v) < 4
        f = NaN(size(y)); return;
    end

    yy = y;
    if any(~v)
        idx = (1:numel(y))';
        yy(~v) = interp1(idx(v), y(v), idx(~v), 'linear', 'extrap');
    end

    h  = hilbert(yy);
    ph = unwrap(angle(h));
    f = [NaN; diff(ph) * (Fs/(2*pi))];
end

function [center, radius] = welzl_min_circle(x, y)
    P = [x(:), y(:)];
    [center, radius] = welzl_recursive(P, [], size(P,1));
end

function [center, radius] = welzl_recursive(P, R, n)
    if n == 0 || numel(R) == 6
        if isempty(R)
            center = [0 0]; radius = 0;
        elseif size(R,1) == 1
            center = R; radius = 0;
        elseif size(R,1) == 2
            center = (R(1,:)+R(2,:))/2;
            radius = norm(R(1,:)-center);
        else
            [center, radius] = circle_from_points(R(1,:), R(2,:), R(3,:));
        end
        return;
    end

    idx = randi(n);
    p = P(idx,:);
    P([idx n],:) = P([n idx],:);

    [center, radius] = welzl_recursive(P, R, n-1);

    if norm(p-center) > radius
        [center, radius] = welzl_recursive(P, [R; p], n-1);
    end
end

function [center, radius] = circle_from_points(A, B, C)
    D = 2*(A(1)*(B(2)-C(2)) + B(1)*(C(2)-A(2)) + C(1)*(A(2)-B(2)));
    center = [ ...
        (norm(A)^2*(B(2)-C(2)) + norm(B)^2*(C(2)-A(2)) + norm(C)^2*(A(2)-B(2))) / D, ...
        (norm(A)^2*(C(1)-B(1)) + norm(B)^2*(A(1)-C(1)) + norm(C)^2*(B(1)-A(1))) / D ...
    ];
    radius = norm(center - A);
end
