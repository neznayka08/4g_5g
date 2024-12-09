
function [distance, initial_bearing, final_bearing] = vincenty(lat1, lon1, lat2, lon2)
    % Параметры эллипсоида WGS-84
    a = 6378137.0; % Большая полуось (метры)
    f = 1 / 298.257223563; % Сжатие
    b = a * (1 - f); % Малая полуось (метры)

    % Преобразование координат в радианы
    lat1 = deg2rad(lat1);
    lon1 = deg2rad(lon1);
    lat2 = deg2rad(lat2);
    lon2 = deg2rad(lon2);

    % Разница координат
    U1 = atan((1 - f) * tan(lat1));
    U2 = atan((1 - f) * tan(lat2));
    L = lon2 - lon1;

    % Инициализация переменных
    lambda = L;
    sinU1 = sin(U1);
    cosU1 = cos(U1);
    sinU2 = sin(U2);
    cosU2 = cos(U2);

    % Итерационный процесс
    maxIter = 100;
    tol = 1e-12;
    for i = 1:maxIter
        sinLambda = sin(lambda);
        cosLambda = cos(lambda);
        sinSigma = sqrt((cosU2 * sinLambda)^2 + (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda)^2);
        if sinSigma == 0
            distance = 0;
            initial_bearing = NaN;
            final_bearing = NaN;
            return;
        end
        cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
        sigma = atan2(sinSigma, cosSigma);
        sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
        cosSqAlpha = 1 - sinAlpha^2;
        cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;
        C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha));
        lambdaP = lambda;
        lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM^2)));
        if abs(lambda - lambdaP) < tol
            break;
        end
    end

    % Расчет расстояния
    uSq = cosSqAlpha * (a^2 - b^2) / b^2;
    A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM^2) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma^2) * (-3 + 4 * cos2SigmaM^2)));
    distance = b * A * (sigma - deltaSigma);

    % Расчет начального и конечного азимута
    initial_bearing = atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);
    final_bearing = atan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda);

    % Преобразование в градусы
    initial_bearing = rad2deg(initial_bearing);
    final_bearing = rad2deg(final_bearing);
end