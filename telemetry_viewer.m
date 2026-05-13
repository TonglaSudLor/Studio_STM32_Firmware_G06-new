%% ROBO-COOK Telemetry Viewer for MATLAB
% This script connects to the STM32 via Serial and plots live motor data.

clear; close all; clc;

% --- CONFIGURATION ---
portName = "COM15"; % <--- UPDATE THIS to your STM32 COM Port
baudRate = 115200;

% Create Serial Port Object
try
    s = serialport(portName, baudRate);
    configureTerminator(s, "CR/LF");
    disp("Connected to " + portName);
catch
    error("Could not open port. Check COM port number and ensure no other app (like Serial Monitor) is using it.");
end

% Initialize Data Storage (Scrolling Window)
maxPoints = 500;
posData = zeros(1, maxPoints);
targetData = zeros(1, maxPoints);

% Setup Plot
figure('Name', 'Robo-Cook Live Telemetry', 'Color', 'w');
hPos = plot(posData, 'b', 'LineWidth', 1.5, 'DisplayName', 'Current Position');
hold on;
hTarget = plot(targetData, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Target (Ghost)');
ylim([-360 360]); % Adjust based on your motor's physical range
legend('Location', 'northeastoutside');
grid on;
title('Live Motor Telemetry (Degrees)');
xlabel('Samples');
ylabel('Position (Deg)');

disp("Listening for data... (Press Ctrl+C to stop)");

% Main Loop
while true
    try
        if s.NumBytesAvailable > 0
            line = readline(s);
            
            % Check for PREVIEW or DATA headers
            if contains(line, "PREVIEW") || contains(line, "DATA")
                parts = split(line, ',');
                if length(parts) >= 3
                    % Data is sent as (Value * 100) to avoid float overhead
                    pos = str2double(parts{2}) / 100.0;
                    target = str2double(parts{3}) / 100.0;
                    
                    % Update scrolling buffers
                    posData = [posData(2:end), pos];
                    targetData = [targetData(2:end), target];
                    
                    % Update Plot Graphics
                    set(hPos, 'YData', posData);
                    set(hTarget, 'YData', targetData);
                    drawnow limitrate;
                end
            end
        end
    catch ME
        disp("Connection Closed: " + ME.message);
        break;
    end
end
