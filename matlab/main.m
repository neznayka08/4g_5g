clear java;
javaaddpath('/home/marina/4_curs/jeromq-0.6.0/target/jeromq-0.6.0.jar')

import org.zeromq.ZMQ.*;
import org.zeromq.*;

port_api = 2110;
context = ZMQ.context(1);
socket_api_proxy = context.socket(ZMQ.REP);
socket_api_proxy.bind(sprintf('tcp://*:%d', port_api));

fprintf("Start\n")
figure(1);
global pauseFlag;
pauseFlag = false;
uicontrol('Style', 'pushbutton', 'String', 'Pause/Resume', ...
              'Position', [20, 20, 100, 30], ...
              'Callback', @(src, event) togglePause());

% Считывание данных из файла example.txt
%data = readDataFromFile('example.txt');

% Инициализация массивов для хранения результатов 
%SNR_values = data(:, 1); % SNR 
%RSRP_values = data(:, 2); % RSRP
%RSRQ_values = data(:, 3); % RSRQ

% Дистанции для расчета (можно задать произвольно, если нужно)
%distances = 1:length(SNR_values); % Например, индексы строк
col = 0;
data = [];
data_n = [];



[L] = OH();


while true
    if ~pauseFlag
        if col == 2000;
            break;
        end
        msg = socket_api_proxy.recv();
        out_data = msg;
        if ~isempty(msg)
            fprintf('received message [%d]\n', length(msg));
            if(length(msg) > 1000)
                [data_complex] = process_data(msg);%, SNR_values, RSRP_values, RSRQ_values, distances);
                data = zeros(1, length(data_complex));
                
                data = data_complex - L;
                
                [Srx] = transmission_channel(data);
                data = transpose(Srx);
                data_single = single(data);
                Rpart = real(data_single);
                IMpart = imag(data_single);
                floatArray = zeros(1, 2*length(data_single));
                floatArray(1:2:end) = Rpart;
                floatArray(2:2:end) = IMpart;
                out_data = typecast(single(floatArray), 'uint8');



                %data = transpose(data);
                col =col +1;
            end
            socket_api_proxy.send(out_data);
        end
    else
        pause(0.1);
    end
end

function [L] = OH()
    % Расчет потерь сигнала по модели COST 231 Hata
    fc = 2560; % Частота в МГц
    hte = 50; % Высота передающей антенны в метрах
    hre = 1.5; % Высота приемной антенны в метрах
    d = 100; % Расстояние между передатчиком и приемником в километрах 1км+ 2км+ 3км+ 5км+ 100км-
    Cm = 0; % Поправочный коэффициент для средних городов и пригородов
    
    % Расчет поправочного коэффициента для высоты приемной антенны
    a_hre = (1.1 * log10(fc) - 0.7) * hre - (1.56 * log10(fc) - 0.8);
    
    % Расчет потерь сигнала
    L = 46.3 + 33.9 * log10(fc) - 13.82 * log10(hte) - a_hre + (44.9 - 6.55 * log10(hte)) * log10(d) + Cm;
end

function togglePause()
    global pauseFlag;
    pauseFlag = ~pauseFlag;
end

function [data_complex] = process_data(data_raw)%, SNR_values, RSRP_values, RSRQ_values, distances)
    data = data_raw / 1.5;
    fs = 23040000;
    fprintf("size data: %d\n", length(data_raw));
    data_slice = data_raw;
    floatArray = typecast(uint8(data_slice), 'single');
    complexArray = complex(floatArray(1:2:end), floatArray(2:2:end));
    data_complex = complexArray(1:128*180);
    fprintf("size complex data: %d\n", length(data_complex));
    cla;
    window = 128;    
    noverlap = 0; 
    nfft = 128;      
    if any(isnan(data_complex))
        data_complex(isnan(data_complex)) = 0;
    end
    
    %subplot(2, 2, 1);
    %x_t = 1:length(data_complex);
    %plot(x_t, data_complex);
    %title('Данные в временной области');
    %xlabel('Отсчеты');
    %ylabel('Амплитуда');
    
    %subplot(2, 2, 2);
    %spectrogram(data_complex, window, noverlap, nfft, fs, 'yaxis');
    %title('Спектрограмма переданных данных');
    %xlabel('Время (сек)');
    %ylabel('Частота (Гц)');
    %colorbar;
    %grid on;
    
    % Отображение данных из файла
    %subplot(2, 2, 3);
    %plot(distances, RSRP_values, '-o');
    %title('RSRP vs Distance');
    %xlabel('Distance (m)');
    %ylabel('RSRP (dBm)');
    
    %subplot(2, 2, 4);
    %plot(distances, SNR_values, '-o');
    %title('SNR vs Distance');
    %xlabel('Distance (m)');
    %ylabel('SNR (dB)');
    
    drawnow;
end

function data = readDataFromFile(filename)
    % Чтение данных из файла
    fileID = fopen(filename, 'r');
    if fileID == -1
        error('Не удалось открыть файл: %s', filename);
    end
    
    % Считывание всех строк из файла
    lines = textscan(fileID, '%f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
    fclose(fileID);
    
    % Преобразование данных в матрицу
    data = [lines{1}, lines{2}, lines{3}];
end

function [Srx] = transmission_channel(complex_data)
    Nv = 10;%количество лучей
    L = length(complex_data);%длинная сигнала
    B = 9*10^6;%полоса инф сигнала
    Ts = 1/B;%длительность дискретного отсчета
    c = 3 * 10^8;%скорость света
    D = randi([10, 300], 1, Nv);%длина луча м потом будем рандомить Nv раз
    t = zeros(1, Nv);%задержка
    fs = 23040000;%несущая

    [~, idx_min] = min(D);
    D = [D(idx_min) , D(1:idx_min-1), D(idx_min+1:end)];
    
    for i = 1:Nv
        t(i)=(D(i)-D(1))/(c*Ts);
        t(i)=round(t(i));
    end
        
    S = zeros(Nv,L+max(t));%сигнальный вектор
    Stx = complex_data;%сигнал из передатчика
    for i = 1:Nv
        for k =  1:(L+t(i))
            if k<= t(i)
                S(i, k) = complex(0,0);
            elseif k>t(i)
                S(i, k) = Stx(k-t(i));
            end
        end
    end
    G = zeros(1, Nv);%затухание
    for i = 1:Nv
        G(i)=c/(4*pi*D(i)*fs);
    end
    
    Smpy = [];%выходной сигнал
    
    for i = 1:Nv
        for k = 1:(L+t(i))
            Smpy(i, k) = S(i, k)*G(i);
        end
    end
        
    Smpy = sum(Smpy,1);
    Srx = [];%сигнал на приемникке
    n = [];%АБГШ
    M = length(Smpy);%длинна вектора сигнала и шума = длина вектора сигнала
    N0 = -150;%?????
    n = transpose(wgn(M, 1, N0));
    Srx = Smpy+n;
end