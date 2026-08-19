% =========================================================================
% Framework 02 | Divagar Vakeesan | PhD | MATLAB Code
% =========================================================================

%% Copyright and Code Availability Notice
% Developed by Divagar Vakeesan as part of his PhD research at the
% University of Manitoba.
%
% Representative sample of Framework 02 - Centroid and Segmentation-Based
% Motion Waveforms. The main processing loop and selected implementation
% details are omitted while associated research publications are under review.
%
% Full implementation is intended for release following publication.
% Copyright (c) 2026 Divagar Vakeesan. All rights reserved.
%
% Citation:
% D. Vakeesan, "Characteristic Distance-Based Barcodes Extracted from
% Vibratory Object Motion in NIR Video Frame Sequences," PhD Thesis,
% University of Manitoba, 2026.

clc; clear; close all; tic;

% ---------------------------------------------------------------------------
% Initialize Video Input and Output
% ---------------------------------------------------------------------------
videoFile   = 'RIL1.mp4'; 
outputFile  = 'Processed_Video_Output.mp4';

% =========================================================================
% OBJECT DETECTION SETTINGS 
% (These are the ONLY settings controlling MotionRegion extraction)
% =========================================================================
alphaBG     = 0.05;   % background update rate
thr         = 40;     % abs-diff threshold
minArea     = 3000;   % keep blobs >= this area (px)
openR       = 3;      % imopen disk radius
closeR      = 5;      % imclose disk radius
dilateR     = 5;      % dilate disk radius for expandedMask / bbox
% =========================================================================

% ---------------------------------------------------------------------------
% Other settings 
% ---------------------------------------------------------------------------
startFrame  = 1;
endFrame    = 61;

height_m      = 1.76;    % m
mass_kg       = 70;      % kg
pixelheight   = 876;     % px reference height in pixels
s_m_per_px    = height_m / pixelheight;

analysisStart = 10;
analysisEnd   = 50;

alphaBarcode  = 1.0;  % |x-mu| >= alpha*sigma

% ---------------------------------------------------------------------------
% VIDEO IO
% ---------------------------------------------------------------------------
vr = VideoReader(videoFile);
fs = vr.FrameRate;
dt = 1/fs;

totalFrames = max(1, floor(vr.Duration * vr.FrameRate));
endFrame    = min(endFrame, totalFrames);
startFrame  = max(1, startFrame);

frameW = vr.Width;
frameH = vr.Height;

% Writer
vw = VideoWriter(outputFile, 'MPEG-4');
vw.FrameRate = fs;
open(vw);

% ---------------------------------------------------------------------------
% HISTORY ARRAYS
% ---------------------------------------------------------------------------
N = endFrame;

centroidHistory   = NaN(N,2);

directionHistory  = NaN(N,1);
trajectoryCurv    = NaN(N,1);

velocityHistory   = NaN(N,1);  % px/s
accelHistory      = NaN(N,1);  % px/s^2
jerkHistory       = NaN(N,1);  % px/s^3
magHistory        = NaN(N,1);  % px (step magnitude)

areaHistory       = NaN(N,1);
bboxBottomYHist   = NaN(N,1);

% Motion segmentation
lineAHistory      = NaN(N,1);
lineBHistory      = NaN(N,1);
lineCHistory      = NaN(N,1);
lineDHistory      = NaN(N,1);

% Motion spread 
spreadHHistory    = NaN(N,1);
spreadWHistory    = NaN(N,1);

% Physical (from centroid)
pV   = NaN(N,1);   % m/s
pA   = NaN(N,1);   % m/s^2
pJ   = NaN(N,1);   % m/s^3
pE   = NaN(N,1);   % J
pP   = NaN(N,1);   % kg*m/s
pF   = NaN(N,1);   % N

%% =========================================================================
% FIGURE 1 — VIDEO PROCESSING + SAVE OUTPUT VIDEO
% =========================================================================
figure('Name','Figure 1: Video Output','Color','w');
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
    tsec  = (frameIdx-1) * dt;

    gray = rgb2gray(frame);

    if isempty(backgroundFrame)
        backgroundFrame = double(gray);
        imshow(frame); drawnow;

         text(gca, 20, 40, sprintf('Frame: %d', frameIdx), ...
    'Color','k', ...
    'FontSize',22, ...
    'FontWeight','bold', ...
    'BackgroundColor','w', ...
    'Margin',4);


        frameForVideo = getframe(gca);
        writeVideo(vw, frameForVideo);


        
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

    % ---- Output frame: WHITE background, red highlight channel ----
    redCh   = uint8(MotionRegion) * 255;
    greenCh = frame(:,:,2);
    blueCh  = frame(:,:,3);

    redCh(~MotionRegion)   = 255;
    greenCh(~MotionRegion) = 255;
    blueCh(~MotionRegion)  = 255;

    highlightedFrame = cat(3, redCh, greenCh, blueCh);

    % ---- Display ----
    imshow(highlightedFrame); hold on;

    % Boundary on MotionRegion (black)
    boundaries = bwboundaries(MotionRegion);
    for k = 1:numel(boundaries)
        b = boundaries{k};
        plot(b(:,2), b(:,1), 'k', 'LineWidth', 2);
    end

    props = regionprops(expandedMask,'Centroid','BoundingBox','Area');

    if ~isempty(props)

        bb = props(1).BoundingBox;
        c  = props(1).Centroid;

        % bbox + centroid
        rectangle('Position', bb, 'EdgeColor','k', 'LineWidth', 2);
        plot(c(1), c(2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor','b');

        centroidHistory(frameIdx,:) = c;
        areaHistory(frameIdx)       = props(1).Area;

        bottomY = bb(2) + bb(4);
        bboxBottomYHist(frameIdx) = bottomY;

        % ---- A/B/C/D distances ----
        leftX   = bb(1);
        rightX  = bb(1) + bb(3);
        topY    = bb(2);
        bottomY = bb(2) + bb(4);

        lineA = abs(c(2) - topY);
        lineB = abs(c(2) - bottomY);
        lineC = abs(c(1) - rightX);
        lineD = abs(c(1) - leftX);

        lineAHistory(frameIdx) = lineA;
        lineBHistory(frameIdx) = lineB;
        lineCHistory(frameIdx) = lineC;
        lineDHistory(frameIdx) = lineD;

        % ---- Motion spread INSIDE LOOP ----
        spreadHHistory(frameIdx) = lineA + lineB; % height = A+B
        spreadWHistory(frameIdx) = lineC + lineD; % width  = C+D

        % ---- Draw dotted lines with gap behind letters ----
        gap = 20;

        % A (centroid to top)
        yLowA  = min(c(2), topY);
        yHighA = max(c(2), topY);
        yMidA  = (yLowA + yHighA)/2;
        plot([c(1), c(1)], [yLowA,  yMidA-gap], ':k', 'LineWidth', 3);
        plot([c(1), c(1)], [yMidA+gap, yHighA], ':k', 'LineWidth', 3);

        % B (centroid to bottom)
        yLowB  = min(c(2), bottomY);
        yHighB = max(c(2), bottomY);
        yMidB  = (yLowB + yHighB)/2;
        plot([c(1), c(1)], [yLowB,  yMidB-gap], ':k', 'LineWidth', 3);
        plot([c(1), c(1)], [yMidB+gap, yHighB], ':k', 'LineWidth', 3);

        % C (centroid to right)
        xLowC  = min(c(1), rightX);
        xHighC = max(c(1), rightX);
        xMidC  = (xLowC + xHighC)/2;
        plot([xLowC,  xMidC-gap], [c(2), c(2)], ':k', 'LineWidth', 3);
        plot([xMidC+gap, xHighC], [c(2), c(2)], ':k', 'LineWidth', 3);

        % D (centroid to left)
        xLowD  = min(c(1), leftX);
        xHighD = max(c(1), leftX);
        xMidD  = (xLowD + xHighD)/2;
        plot([xLowD,  xMidD-gap], [c(2), c(2)], ':k', 'LineWidth', 3);
        plot([xMidD+gap, xHighD], [c(2), c(2)], ':k', 'LineWidth', 3);



         % Letters inside box
        insideProps = {'Color','k','FontSize',20,'FontWeight','bold', ...
                       'HorizontalAlignment','center','VerticalAlignment','middle'};
        text(c(1), yMidA, 'A', insideProps{:});
        text(c(1), yMidB, 'B', insideProps{:});
        text(xMidC, c(2), 'C', insideProps{:});
        text(xMidD, c(2), 'D', insideProps{:});
        

      % ---- RIGHT SIDE A/B/C/D (2 LINES, BOLD) ----
rightX = frameW - 120;   % distance from right border
startY = 200;            % vertical position
gapY   = 40;             % spacing between lines

rightProps = { ...
    'Color','k', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle', ...
    'BackgroundColor','w', ...
    'Margin',4};

% Line 1: A and B
text(rightX, startY, ...
    sprintf('A = %.1f   |   B = %.1f', lineA, lineB), ...
    rightProps{:});

% Line 2: C and D
text(rightX, startY + gapY, ...
    sprintf('C = %.1f   |   D = %.1f', lineC, lineD), ...
    rightProps{:});



        % ---- Kinematics from centroid ----
        if frameIdx > startFrame && all(isfinite(centroidHistory(frameIdx-1,:)))
            cPrev = centroidHistory(frameIdx-1,:);

            dx = c(1) - cPrev(1);
            dy = c(2) - cPrev(2);

            % Velocity (px/s)
            vpx = hypot(dx, dy) * fs;
            velocityHistory(frameIdx) = vpx;

            % Magnitude (px)
            magHistory(frameIdx) = hypot(dx, dy);

            % Direction (flip y)
            deltaY = (frameH - c(2)) - (frameH - cPrev(2)); % = -(dy)
            if dx == 0 && deltaY == 0
                directionHistory(frameIdx) = NaN;
            else
                directionHistory(frameIdx) = atan2d(deltaY, dx);
            end

            % Arrow
            scaleArrow = 2.5;
            quiver(c(1), c(2), scaleArrow*dx, scaleArrow*(-deltaY), ...
                   'Color','k','LineWidth',2,'MaxHeadSize',3.5);

            % Curvature (degrees/px)
            if frameIdx > startFrame+1 && isfinite(directionHistory(frameIdx-1))
                dd = abs(directionHistory(frameIdx) - directionHistory(frameIdx-1));
                trajectoryCurv(frameIdx) = dd / max(hypot(dx, dy), eps);
            end

            % Acc / Jerk (px)
            if isfinite(velocityHistory(frameIdx-1))
                apx = (velocityHistory(frameIdx) - velocityHistory(frameIdx-1)) * fs;
                accelHistory(frameIdx) = apx;

                if frameIdx > startFrame+1 && isfinite(accelHistory(frameIdx-1))
                    jpx = (accelHistory(frameIdx) - accelHistory(frameIdx-1)) * fs;
                    jerkHistory(frameIdx) = jpx;
                end
            end

            % Physical conversion
            pV(frameIdx) = vpx * s_m_per_px;
            if isfinite(accelHistory(frameIdx))
                pA(frameIdx) = accelHistory(frameIdx) * s_m_per_px;
            end
            if isfinite(jerkHistory(frameIdx))
                pJ(frameIdx) = jerkHistory(frameIdx) * s_m_per_px;
            end

            if isfinite(pV(frameIdx))
                pE(frameIdx) = 0.5 * mass_kg * (pV(frameIdx)^2);
                pP(frameIdx) = mass_kg * pV(frameIdx);
            end
            if isfinite(pA(frameIdx))
                pF(frameIdx) = mass_kg * pA(frameIdx);
            end
        end
    end

    % ---- Text overlays ----
    text(gca, 20, 40, sprintf('Frame: %d', frameIdx), ...
    'Color','k', ...
    'FontSize',22, ...
    'FontWeight','bold', ...
    'BackgroundColor','w', ...
    'Margin',4);

    
    %text(600, 60, sprintf('Time  : %.2f s', tsec),  'Color','k','FontSize',20,'FontWeight','bold');

   % ---- RIGHT SIDE INFO BLOCK (Angle + Centroid) ----
rightX = frameW - 100;   % right margin alignment
startY = 60;             % first line position
gapY   = 40;             % vertical spacing

infoProps = { ...
    'Color','k', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','right', ...
    'VerticalAlignment','middle', ...
    'BackgroundColor','w', ...
    'Margin',4};

% ---- Angle ----
if isfinite(directionHistory(frameIdx))
    ang = directionHistory(frameIdx);
    if ang >= 0
        angStr = sprintf('Angle: %.2f° (Upward)', ang);
    else
        angStr = sprintf('Angle: %.2f° (Downward)', ang);
    end
else
    angStr = 'Angle: NaN';
end

text(rightX, startY + 0*gapY, angStr, infoProps{:});

% ---- Centroid Position ----
if all(isfinite(centroidHistory(frameIdx,:)))
    cx = centroidHistory(frameIdx,1);
    cy = centroidHistory(frameIdx,2);

    text(rightX, startY + 1*gapY, ...
        sprintf('Centroid X: %.1f px', cx), infoProps{:});

    text(rightX, startY + 2*gapY, ...
        sprintf('Centroid Y: %.1f px', cy), infoProps{:});
else
    text(rightX, startY + 1*gapY, 'Centroid X: NaN', infoProps{:});
    text(rightX, startY + 2*gapY, 'Centroid Y: NaN', infoProps{:});
end


    % ---- Grid ----
    axis on; box on; grid on;

    xticks(0:50:frameW);
    yticks(0:50:frameH);

    xLabelTicks = 0:100:frameW;
    yLabelTicks = 0:100:frameH;

    xAll = 0:50:frameW;
    yAll = 0:50:frameH;

    xLabels = arrayfun(@num2str, xAll, 'UniformOutput', false);
    yLabels = arrayfun(@num2str, yAll, 'UniformOutput', false);

    xLabels(~ismember(xAll, xLabelTicks)) = {''};
    yLabels(~ismember(yAll, yLabelTicks)) = {''};

    set(gca,'XTickLabel',xLabels,'YTickLabel',yLabels, ...
            'FontSize',25,'Layer','top','Visible','on');

    hold off;
    drawnow;

    % ---- Save frame ----
    frameForVideo = getframe(gca);
    writeVideo(vw, frameForVideo);
end

close(vw);
disp('Done: Figure-1 video displayed and output saved.');

%% ---------------- RANGES (PLOTS = ANALYSIS WINDOW ONLY) ----------------
analysisStart = max(1, analysisStart);
analysisEnd   = min(endFrame, analysisEnd);

analysisRange = (analysisStart:analysisEnd)';  % PLOT + STATS + BARCODE
plotRange     = analysisRange;

Kplot = numel(plotRange);

%% =========================================================================
% FIGURE 2 — CENTROID TRAJECTORY (ANALYSIS WINDOW ONLY)
%            + STRAIGHT VERTICAL ARROWS
%            + AUTO FRAME SIZE FROM VIDEO
% =========================================================================

% ---- Get frame size directly from video ----
vr = VideoReader(videoFile);
frameW = vr.Width;
frameH = vr.Height;

figure('Name','Figure 2: Centroid Trajectory',...
       'NumberTitle','off','Color','w',...
       'Position',[200 120 1100 850]);

% Extract centroid data
xC = centroidHistory(plotRange,1);
yC = centroidHistory(plotRange,2);

% Plot trajectory
plot(xC, yC, 'b.-', ...
     'MarkerSize', 28, ...
     'LineWidth', 1.6);

grid on; box on;

% IMPORTANT: equal axis scaling
axis image

% Match real video dimensions
xlim([0 frameW]);
ylim([0 frameH]);

% Reverse Y (image coordinate system)
set(gca,'YDir','reverse');

xlabel('Frame Width (px)','FontSize',20);
ylabel('Frame Height (px)','FontSize',20);
set(gca,'FontSize',18,'LineWidth',1.6);

%title('Centroid Trajectory (Analysis Window)','FontSize',22);

% -------------------------------------------------------------------------
% STRAIGHT VERTICAL ARROWS (ALTERNATING TOP–BOTTOM)
% -------------------------------------------------------------------------
hold on;

valid = isfinite(xC) & isfinite(yC);
xV = xC(valid);
yV = yC(valid);
fV = plotRange(valid);

stepShow = 1;       % change to 2 if crowded
offsetY  = 80;      % vertical spacing (px)
fontSz   = 22;

for i = 1:stepShow:numel(fV)

    xText = xV(i);  % SAME X → vertical arrow

    if mod(i,2) == 1
        % ---- TOP ----
        yText = yV(i) - offsetY;
    else
        % ---- BOTTOM ----
        yText = yV(i) + offsetY;
    end

    % Clamp inside frame
    yText = max(min(yText, frameH-20), 20);

    % ---- STRAIGHT VERTICAL ARROW (NO SCALING) ----
    quiver(xText, yText, ...
           0, (yV(i) - yText), ...
           0, ...                  % disable autoscale
           'Color','k', ...
           'LineWidth',1.8, ...
           'MaxHeadSize',0.5);

   % ---- Frame number ----
text(xText, yText, sprintf('%d', fV(i)), ...
    'FontSize',fontSz, ...
    'FontWeight','normal', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', ...
    'BackgroundColor','w', ...
    'Margin',4);

end

hold off;

%% =========================================================================
% FIGURE 3 — KINEMATICS (3x3) (ANALYSIS WINDOW ONLY)
% =========================================================================
figure('Name','Figure 3: Kinematics (3x3)',...
       'NumberTitle','off','Color','w',...
       'Position',[60 60 1800 950]);

labelFS = 18;     % <-- Axis label font size
axisFS  = 15;     % <-- Tick font size
titleFS = 18;     % <-- Title font size

% -------------------------------------------------------------------------
subplot(3,3,1);
plot(plotRange, magHistory(plotRange), 'k.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Magnitude (px)','FontSize',labelFS);
grid on; box on;
title('Magnitude','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,2);
plot(plotRange, directionHistory(plotRange), 'k.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Direction (deg)','FontSize',labelFS);
grid on; box on;
title('Direction','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,3);
plot(plotRange, trajectoryCurv(plotRange), 'k.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Curvature (deg/px)','FontSize',labelFS);
grid on; box on;
title('Trajectory Curvature','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,4);
plot(plotRange, pV(plotRange), 'b.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Velocity (m/s)','FontSize',labelFS);
grid on; box on;
title('Velocity','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,5);
plot(plotRange, pA(plotRange), 'b.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Acceleration (m/s^2)','FontSize',labelFS);
grid on; box on;
title('Acceleration','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,6);
plot(plotRange, pJ(plotRange), 'b.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Jerk (m/s^3)','FontSize',labelFS);
grid on; box on;
title('Jerk','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,7);
plot(plotRange, pE(plotRange), 'r.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Energy (J)','FontSize',labelFS);
grid on; box on;
title('Kinetic Energy','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,8);
plot(plotRange, pP(plotRange), 'r.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Momentum (kg·m/s)','FontSize',labelFS);
grid on; box on;
title('Momentum','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);

% -------------------------------------------------------------------------
subplot(3,3,9);
plot(plotRange, pF(plotRange), 'r.-','MarkerSize',10,'LineWidth',1);
xlabel('Frame Number','FontSize',labelFS);
ylabel('Force (N)','FontSize',labelFS);
grid on; box on;
title('Resultant Force','FontSize',titleFS);
set(gca,'FontSize',axisFS,'LineWidth',1.3);


%% =========================================================================
% HILBERT/FFT PLOT SETTINGS (shared) — based on plotRange
% =========================================================================
titleFS = 16; labelFS = 14; axisFS = 12; axisLW = 1.2;
xStep   = max(1, round(numel(plotRange)/10));

darkForestCyan   = [0.00 0.45 0.45];
darkSteelIndigo  = [0.20 0.25 0.55];

colA = [0.4940 0.1840 0.5560];
colB = [0.6350 0.0780 0.1840];
colC = [0.5574 0.4164 0.0750];
colD = [0.2796 0.4044 0.1128];
colW = [0.4940 0.1840 0.5560];
colH = [0.8500 0.3250 0.0980];

xMin = min(plotRange); xMax = max(plotRange);

%% =========================================================================
% FIGURE 4 — MOTION CENTROID (Hor_X, Ver_Y): Signal&Env | Phase | IF | FFT
%            (PLOT WINDOW ONLY) + IF stats computed from analysisRange (same)
% =========================================================================
sigX = centroidHistory(plotRange,1);
sigY = centroidHistory(plotRange,2);

[sigX, xX] = cleanSig(sigX, plotRange);
[sigY, xY] = cleanSig(sigY, plotRange);

[hX, envX, phX, fXinst, fXaxis, P1X] = hilbPack(sigX, fs);
[hY, envY, phY, fYinst, fYaxis, P1Y] = hilbPack(sigY, fs);

figure('Name','Figure 4: Motion Centroid (Hor/Ver)','NumberTitle','off','Color','w');

% ---- Hor_X: Signal + Envelope (ONLY column 1 changed) ----
subplot(4,4,1);
plot(xX, sigX, '-',  'Color', darkForestCyan, 'LineWidth',1.5); hold on;     % <-- CHANGED
plot(xX, envX, '--', 'Color', darkForestCyan, 'LineWidth',1.5);
title('Signal & Envelope (Hor\_X)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,2); plainPlot(xX, phX, darkForestCyan);
title('Instantaneous Phase (Hor\_X)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,3); freqPlotShade(xX, fXinst, darkForestCyan, analysisRange);
title('Instantaneous Frequency (Hor\_X)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,4); plainPlot(fXaxis, P1X, darkForestCyan);
title('Frequency Spectrum (Hor\_X)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

% ---- Ver_Y: Signal + Envelope (ONLY column 1 changed) ----
subplot(4,4,5);
plot(xY, sigY, '-',  'Color', darkSteelIndigo, 'LineWidth',1.5); hold on;    % <-- CHANGED
plot(xY, envY, '--', 'Color', darkSteelIndigo, 'LineWidth',1.5);
title('Signal & Envelope (Ver\_Y)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,6); plainPlot(xY, phY, darkSteelIndigo);
title('Instantaneous Phase (Ver\_Y)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,7); freqPlotShade(xY, fYinst, darkSteelIndigo, analysisRange);
title('Instantaneous Frequency (Ver\_Y)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,8); plainPlot(fYaxis, P1Y, darkSteelIndigo);
title('Frequency Spectrum (Ver\_Y)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

%% =========================================================================
% FIGURE 5 — MOTION SPREAD (W/H): Signal&Env | Phase | IF | FFT (PLOT WINDOW)
% =========================================================================
sigW = spreadWHistory(plotRange);
sigH = spreadHHistory(plotRange);

[sigW, xW] = cleanSig(sigW, plotRange);
[sigH, xH] = cleanSig(sigH, plotRange);

[hW, envW, phW, fWinst, fWaxis, P1W] = hilbPack(sigW, fs);
[hH, envH, phH, fHinst, fHaxis, P1H] = hilbPack(sigH, fs);

figure('Name','Figure 5: Motion Spread (W/H)','NumberTitle','off','Color','w');

% Spread_W
subplot(4,4,1);
plot(xW, sigW, '-',  'Color', colW, 'LineWidth',1.5); hold on;               % <-- CHANGED
plot(xW, envW, '--', 'Color', colW, 'LineWidth',1.5);
title('Signal & Envelope (Spread\_W = C+D)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,2); plainPlot(xW, phW, colW);
title('Instantaneous Phase (Spread\_W)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,3); freqPlotShade(xW, fWinst, colW, analysisRange);
title('Instantaneous Frequency (Spread\_W)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,4); plainPlot(fWaxis, P1W, colW);
title('Frequency Spectrum (Spread\_W)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

% Spread_H
subplot(4,4,5);
plot(xH, sigH, '-',  'Color', colH, 'LineWidth',1.5); hold on;               % <-- CHANGED
plot(xH, envH, '--', 'Color', colH, 'LineWidth',1.5);
title('Signal & Envelope (Spread\_H = A+B)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,6); plainPlot(xH, phH, colH);
title('Instantaneous Phase (Spread\_H)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,7); freqPlotShade(xH, fHinst, colH, analysisRange);
title('Instantaneous Frequency (Spread\_H)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,8); plainPlot(fHaxis, P1H, colH);
title('Frequency Spectrum (Spread\_H)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

%% =========================================================================
% FIGURE 6 — MOTION SEGMENTATION (A,B,C,D): Signal&Env | Phase | IF | FFT
% =========================================================================
sigA = lineAHistory(plotRange);
sigB = lineBHistory(plotRange);
sigC = lineCHistory(plotRange);
sigD = lineDHistory(plotRange);

[sigA, xA_] = cleanSig(sigA, plotRange);
[sigB, xB_] = cleanSig(sigB, plotRange);
[sigC, xC_] = cleanSig(sigC, plotRange);
[sigD, xD_] = cleanSig(sigD, plotRange);

[hA, envA, phA, fAinst, fAaxis, P1A] = hilbPack(sigA, fs);
[hB, envB, phB, fBinst, fBaxis, P1B] = hilbPack(sigB, fs);
[hC, envC, phC, fCinst, fCaxis, P1C] = hilbPack(sigC, fs);
[hD, envD, phD, fDinst, fDaxis, P1D] = hilbPack(sigD, fs);

figure('Name','Figure 6: Motion Segmentation (A/B/C/D)','NumberTitle','off','Color','w');

% A
subplot(4,4,1);
plot(xA_, sigA, '-',  'Color', colA, 'LineWidth',1.5); hold on;              % <-- CHANGED
plot(xA_, envA, '--', 'Color', colA, 'LineWidth',1.5);
title('Signal & Envelope (A Upper)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,2);  plainPlot(xA_, phA, colA);
title('Instantaneous Phase (A)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,3);  freqPlotShade(xA_, fAinst, colA, analysisRange);
title('Instantaneous Frequency (A)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,4);  plainPlot(fAaxis, P1A, colA);
title('Frequency Spectrum (A)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

% B
subplot(4,4,5);
plot(xB_, sigB, '-',  'Color', colB, 'LineWidth',1.5); hold on;              % <-- CHANGED
plot(xB_, envB, '--', 'Color', colB, 'LineWidth',1.5);
title('Signal & Envelope (B Lower)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,6);  plainPlot(xB_, phB, colB);
title('Instantaneous Phase (B)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,7);  freqPlotShade(xB_, fBinst, colB, analysisRange);
title('Instantaneous Frequency (B)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,8);  plainPlot(fBaxis, P1B, colB);
title('Frequency Spectrum (B)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

% C
subplot(4,4,9);
plot(xC_, sigC, '-',  'Color', colC, 'LineWidth',1.5); hold on;              % <-- CHANGED
plot(xC_, envC, '--', 'Color', colC, 'LineWidth',1.5);
title('Signal & Envelope (C Front)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,10); plainPlot(xC_, phC, colC);
title('Instantaneous Phase (C)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,11); freqPlotShade(xC_, fCinst, colC, analysisRange);
title('Instantaneous Frequency (C)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,12); plainPlot(fCaxis, P1C, colC);
title('Frequency Spectrum (C)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);

% D
subplot(4,4,13);
plot(xD_, sigD, '-',  'Color', colD, 'LineWidth',1.5); hold on;              % <-- CHANGED
plot(xD_, envD, '--', 'Color', colD, 'LineWidth',1.5);
title('Signal & Envelope (D Back)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Amplitude (px)','FontSize',labelFS);
legend({'Signal','Envelope'},'FontSize',10,'Location','northeast');           % <-- CHANGED
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,14); plainPlot(xD_, phD, colD);
title('Instantaneous Phase (D)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Phase (rad)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,15); freqPlotShade(xD_, fDinst, colD, analysisRange);
title('Instantaneous Frequency (D)','FontSize',titleFS);
xlabel('Frame Number','FontSize',labelFS); ylabel('Frequency (Hz)','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW); xticks(xMin:xStep:xMax);

subplot(4,4,16); plainPlot(fDaxis, P1D, colD);
title('Frequency Spectrum (D)','FontSize',titleFS);
xlabel('Frequency (Hz)','FontSize',labelFS); ylabel('|P_1(f)|','FontSize',labelFS);
grid on; set(gca,'FontSize',axisFS,'LineWidth',axisLW);


%% =========================================================================
% FIGURE 7 — 8-CHARACTERISTIC INSTANTANEOUS-FREQUENCY BARCODE (IF only)
% NOTE: Barcode + mean/sd computed ONLY from analysisRange (same as plotRange)
% =========================================================================
xSigB = fillmissing(centroidHistory(analysisRange,1),'linear','EndValues','nearest');
ySigB = fillmissing(centroidHistory(analysisRange,2),'linear','EndValues','nearest');

AsigB = fillmissing(lineAHistory(analysisRange),'linear','EndValues','nearest');
BsigB = fillmissing(lineBHistory(analysisRange),'linear','EndValues','nearest');
CsigB = fillmissing(lineCHistory(analysisRange),'linear','EndValues','nearest');
DsigB = fillmissing(lineDHistory(analysisRange),'linear','EndValues','nearest');

wSigB = fillmissing(spreadWHistory(analysisRange),'linear','EndValues','nearest'); % C+D
hSigB = fillmissing(spreadHHistory(analysisRange),'linear','EndValues','nearest'); % A+B

IF = @(sig) [NaN; diff(unwrap(angle(hilbert(sig(:))))) * (fs/(2*pi))];

fx = IF(xSigB);
fy = IF(ySigB);
fA = IF(AsigB);
fB = IF(BsigB);
fC = IF(CsigB);
fD = IF(DsigB);
fW = IF(wSigB);
fH = IF(hSigB);

K2 = min([numel(fx),numel(fy),numel(fA),numel(fB),numel(fC),numel(fD),numel(fW),numel(fH)]);
framesBC = analysisRange(1:K2);

XMat8 = [ ...
    fx(1:K2)'; ...
    fy(1:K2)'; ...
    fA(1:K2)'; ...
    fB(1:K2)'; ...
    fC(1:K2)'; ...
    fD(1:K2)'; ...
    fW(1:K2)'; ...
    fH(1:K2)'  ...
];

muVec  = mean(XMat8, 2, 'omitnan');
sdVec  = std(XMat8,  0, 2, 'omitnan');

psi = false(8, K2);
for r = 1:8
    if ~isfinite(sdVec(r)) || sdVec(r)==0
        psi(r,:) = false;
    else
        psi(r,:) = abs(XMat8(r,:) - muVec(r)) >= alphaBarcode * sdVec(r);
    end
end
psi = double(psi);

figure('Name','Figure 7: 8-Characteristic IF Barcode', 'NumberTitle','off', ...
       'Position',[100 100 1900 380], 'Color','w');
hold on;
set(gca,'Color',[0.94 0.94 0.94]);

barW  = 0.95;
gap   = 0.04;
laneH = 0.90;

rectangle('Position',[0.5, 0.5, K2, 8], 'EdgeColor','k', 'LineWidth',3);

for c = 1:K2
    xLeft = c - barW/2;
    for r = 1:8
        yBottom = r - laneH/2;
        fc = [1 1 1];
        if psi(r,c) == 1
            fc = [0 0 0];
        end
        rectangle('Position',[xLeft + gap/2, yBottom, barW-gap, laneH], ...
                  'FaceColor',fc,'EdgeColor','none');
    end
end

set(gca,'YDir','normal');
ylim([0.5 8.5]);
xlim([0.5 K2+0.5]);

yLabels = {'Hor_{X}','Ver_{Y}','Upper_{A}','Lower_{B}','Front_{C}','Back_{D}','Spread_{W}','Spread_{H}'};
set(gca,'YTick',1:8,'YTickLabel',yLabels,'FontSize',16);

set(gca,'XTick',1:K2,'XTickLabel',framesBC,'FontSize',14,'TickDir','in');
xlabel('Frame Number','FontSize',18);
ylabel('Characteristics','FontSize',18);

title('Framework 02 - Running : Centroid Based Characteristic Distance Barcode (2 Centroid + 4 Segments + 2 Spread)', 'FontSize',18);

yline(2.5,'k-','LineWidth',1.2,'Alpha',0.5);
yline(6.5,'k-','LineWidth',1.2,'Alpha',0.5);

box on; grid on;
set(gca,'XGrid','on','GridAlpha',0.12,'YGrid','off');
hold off;

disp('ALL DONE: Figure1..Figure7 generated.');



%% =========================================================================
% FULL BLOCK: Journal-Style Stats + Correlation (SHORT NAMES ONLY)
%% =========================================================================

% Short labels (used everywhere)
charNames = { ...
    'Hor_X'; ...
    'Ver_Y'; ...
    'Upper_A'; ...
    'Lower_B'; ...
    'Front_C'; ...
    'Back_D'; ...
    'Spread_W'; ...
    'Spread_H' };

%% ------------------------ BARCODE STATISTICS ------------------------------

Nframes = K2;                          % frames used in barcode
exceedCount = sum(psi, 2);             % number of exceedances
exceedRate  = (exceedCount./Nframes)*100;
thresholdVals = alphaBarcode .* sdVec(:);

%% =========================================================================
% CLEAN JOURNAL-STYLE PRINT
%% =========================================================================

fprintf('\n=============================================================================\n');
fprintf('Framework 02 — Instantaneous Frequency Statistical Summary\n');
fprintf('=============================================================================\n\n');

fprintf('%-3s %-12s %12s %12s %16s %10s %14s %12s\n', ...
    'ID', ...
    'Characteristic', ...
    'Mean (Hz)', ...
    'SD (Hz)', ...
    'Threshold (α·σ)', ...
    'Frames', ...
    'Exceed', ...
    'E-Rate (%)');

fprintf('-----------------------------------------------------------------------------\n');

for i = 1:8
    fprintf('%-3d %-12s %12.4f %12.4f %16.4f %10d %14d %12.2f\n', ...
        i, ...
        charNames{i}, ...
        muVec(i), ...
        sdVec(i), ...
        thresholdVals(i), ...
        Nframes, ...
        exceedCount(i), ...
        exceedRate(i));
end

fprintf('=============================================================================\n\n');

%% =========================================================================
% CORRELATION MATRIX — Pearson (3 Decimal Precision)
%% =========================================================================

validCols = all(isfinite(XMat8),1);
Xcorr = XMat8(:,validCols)';   % N x 8

if size(Xcorr,1) < 3
    warning('Not enough valid samples for correlation.');
else

    [R, P] = corrcoef(Xcorr);

    % Round to 3 decimals
    R3 = round(R, 3);
    P3 = round(P, 3);

    CorrTable = array2table(R3, ...
        'VariableNames', charNames, ...
        'RowNames', charNames);

    disp('=== Pearson Correlation Matrix ===');
    disp(CorrTable);

    % Optional: p-values also 3 decimals
    PTable = array2table(P3, ...
        'VariableNames', charNames, ...
        'RowNames', charNames);

    disp('=== Pearson Correlation p-values ===');
    disp(PTable);

    % Heatmap (still full precision visually)
    figure('Name','Correlation Matrix (Framework-02)','Color','w');
    imagesc(R3);
    colorbar;
    colormap(jet);
    caxis([-1 1]);
    axis square;

    set(gca,'XTick',1:8,'XTickLabel',charNames,...
            'YTick',1:8,'YTickLabel',charNames,...
            'FontSize',12);

    %title('Correlation Matrix');
end

%% =========================================================================
% EXPORT: 8-Characteristic Instantaneous Frequency (IF) per analysis frame
% Saves a CSV with columns: Frame, Hor_X, Ver_Y, Upper_A, Lower_B, Front_C, Back_D, Spread_W, Spread_H
% REQUIREMENTS: analysisRange, fs, centroidHistory, lineAHistory, lineBHistory, lineCHistory, lineDHistory,
%               spreadWHistory, spreadHHistory must already exist.
%% =========================================================================

% Ensure column vector frames
framesIF = analysisRange(:);

% Fill missing signals over analysis window
xSigB = fillmissing(centroidHistory(framesIF,1),'linear','EndValues','nearest');
ySigB = fillmissing(centroidHistory(framesIF,2),'linear','EndValues','nearest');

AsigB = fillmissing(lineAHistory(framesIF),'linear','EndValues','nearest');
BsigB = fillmissing(lineBHistory(framesIF),'linear','EndValues','nearest');
CsigB = fillmissing(lineCHistory(framesIF),'linear','EndValues','nearest');
DsigB = fillmissing(lineDHistory(framesIF),'linear','EndValues','nearest');

wSigB = fillmissing(spreadWHistory(framesIF),'linear','EndValues','nearest'); % C+D
hSigB = fillmissing(spreadHHistory(framesIF),'linear','EndValues','nearest'); % A+B

% IF operator
IF = @(sig) [NaN; diff(unwrap(angle(hilbert(sig(:))))) * (fs/(2*pi))];

% Compute IF (same length as framesIF)
Hor_X   = IF(xSigB);
Ver_Y   = IF(ySigB);
Upper_A = IF(AsigB);
Lower_B = IF(BsigB);
Front_C = IF(CsigB);
Back_D  = IF(DsigB);
Spread_W = IF(wSigB);
Spread_H = IF(hSigB);

% Build table (no trimming — EXACTLY all analysis frames)
IF_Table = table( ...
    framesIF, ...
    Hor_X, Ver_Y, Upper_A, Lower_B, Front_C, Back_D, Spread_W, Spread_H, ...
    'VariableNames', {'Frame','Hor_X','Ver_Y','Upper_A','Lower_B','Front_C','Back_D','Spread_W','Spread_H'} );

% Write CSV
csvName = sprintf('FW02_IF_8chars_frames_%d_to_%d.csv', framesIF(1), framesIF(end));
writetable(IF_Table, csvName);

disp(['Saved IF CSV: ', csvName]);



%% =========================================================================
% EXPORT: Framework-02 8-Characteristic IF Barcode (WIDE FORMAT ONLY)
% psi: 8 x K2
% framesBC: K2 x 1 (analysisRange frames)
%% =========================================================================

framesBC = framesBC(:);     % ensure column

% Transpose barcode to K2 x 8
psiWide = psi.';            % each row = one frame

BarcodeWideTable = array2table(psiWide, ...
    'VariableNames', { ...
    'Hor_X','Ver_Y','Upper_A','Lower_B','Front_C','Back_D','Spread_W','Spread_H' });

% Add Frame column in front
BarcodeWideTable = addvars(BarcodeWideTable, framesBC, ...
    'Before', 1, 'NewVariableNames', 'Frame');

% File name
csvWide = sprintf('FW02_Barcode_8chars_frames_%d_to_%d.csv', ...
                  framesBC(1), framesBC(end));

% Write CSV
writetable(BarcodeWideTable, csvWide);

disp(['Saved barcode CSV: ', csvWide]);
%% =========================================================================
% LOCAL HELPERS
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

    plot(x, y, '.-', ...
        'Color', lineColor, ...
        'MarkerSize', 12, ...
        'LineWidth', 1.5);
    hold on;
end

% UPDATED: stats (mu/sd) computed ONLY from statsFrames (analysisRange)
function freqPlotShade(x, y, lineColor, statsFrames)
    x = x(:); y = y(:);
    v = isfinite(x) & isfinite(y);
    x = x(v); y = y(v);
    if isempty(x), return; end

    % --- STRICT stats window: ONLY use analysis frames ---
    statsFrames = statsFrames(:);
    idxStats = ismember(x, statsFrames);

    yStats = y(idxStats);

    if isempty(yStats) || all(~isfinite(yStats))
        % No valid samples in analysis range => do NOT fallback to full range
        plot(x, y, '.-', 'Color', lineColor, 'MarkerSize', 12, 'LineWidth', 1.5);
        hold on;
        warning('freqPlotShade: No valid samples in analysisRange for stats (mu/sd). Stats skipped.');
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

    % Red points ONLY inside analysis window
    idxRed = idxStats & ((y > upper) | (y < lower));
    if any(idxRed)
        plot(x(idxRed), y(idxRed), 'ro', 'MarkerSize', 8, ...
            'MarkerFaceColor','r', 'LineWidth', 1.2);
    end
end
