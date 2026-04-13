%% Obtención de información de personalización mediante dos sesiones
% Elaborado por: Karla González Cabrales, karla.gonzalezcs@udlap.mx
%
%
% PARÁMETROS DE ENTRADA SELECCIONADOS DESEDE LA APP:
% s1:              : nombre o ruta del archivo .mat de la primera sesión.
% s2:              : nombre o ruta del archivo .mat de la segunda sesión.
% nombreUsuario:   : nombre del usuario. 
%
% Como PARÁMETRO DE SALIDA, se obtiene la ruta del archivo generado .txt
% con la información de personalización. Adicionalmente, se generan los
% siguientes archivos:
%       model_c1c2_nombreUsuario.mat
%       model_c1c3_nombreUsuario.mat
%       model_c2c3_nombreUsuario.mat
% Cada archivo contiene la estructura generada correspondiente al mejor
% modelo para cada par de características, así como los mejores canales,
% sus mejores frecuencias asociadas a la extracción de caractarísticas, y
% la puntuación, en forma de porcentaje, de la validación del modelo de
% clasificación.
%
% Es importante que tanto los archivos de las sesiones y el archivo
% "info_electrodos_frecuencias.mat" se encuentren en la misma carpeta que
% esta app y función.
%
% Para obtener las características, se usa la función bandpoweren distintas
% bandas de frecuencia para ventanas de 2 segundos y 1 segundo de
% solapamiento entre cada una. 
%


function log_file=entrenar_2sesiones(s1, s2, nombreUsuario)
    Fs=250; 
    Wp1= 5; 
    Wp2= 30;
    %filtro pasa bandas, conserva la información relevante de la señal.
    d= designfilt('bandpassiir','Filterorder', 6, 'HalfPowerFrequency1',Wp1,'HalfPowerFrequency2',Wp2, ...
        'SampleRate',Fs);
    
    load("info_electrodos_frecuencias.mat", 'info_electrodos_frecuencias');
    
    ses1= load(s1);
    s_1 = ses1.s;
    signal_1 = ses1.signal; 

    ses2= load(s2);
    s_2 = ses2.s;
    signal_2 = ses2.signal;

    nombreUsuario= regexprep(nombreUsuario, '\W', '_');
    
    logFile = sprintf('log_%s_%s.txt', nombreUsuario, datestr(now,'yyyy-mm-dd_HHMMSS'));
    diary off;                      
    diary(logFile); % captura de la Command Window
    c = onCleanup(@() diary('off')); 
    log_file = fullfile(pwd, logFile);


    s= [s_1, s_2];
    signal= cat(3, signal_1, signal_2);
    
    % Separación de los estímulos de acuerdo a su clase
    class1= signal(:,:,[find(s==1)]);
    class2= signal(:,:,[find(s==2)]); 
    class3= signal(:,:,[find(s==3)]);
    
    %ventanas de 2 segundos con 1 de solapamiento
    limite_1=[1, 251, 501, 751];
    limite_2=[500, 750, 1000, 1250];
    % índices del acomodo de las características
    lim_1_vect= [1, 21, 41, 61];
    lim_2_vect= [20, 40, 60, 80];

    %   análisis de la clase 1
    
    FeatureVector_c1_f1=zeros(8,80);
        for a=1:4
            c1=class1(:,limite_1(:,a):limite_2(:,a),:); %tomar la ventana
                 for j=1:8
                    %analizar por electrodo
                    electrodoc1= c1(j,:,:); 
                    aplastadac1= squeeze(electrodoc1); 
                    % aplicar el filtro
                    filtradac1= filtfilt(d,aplastadac1);
                    % obtener las características en cierta banda de
                    % frecuencia
                    potenciac1= bandpower(filtradac1,Fs,[5 10]);
                    % almacenar en el vector con el índice correspondiente 
                    FeatureVector_c1_f1(j,lim_1_vect(:,a):lim_2_vect(:,a))=potenciac1;
                 end 
        end
       
    FeatureVector_c1_f2=zeros(8,80);
    for a_2=1:4
        c1_2=class1(:,limite_1(:,a_2):limite_2(:,a_2),:);
         for j_2=1:8
            electrodoc1_2= c1_2(j_2,:,:);
            aplastadac1_2= squeeze(electrodoc1_2); 
            filtradac1_2= filtfilt(d,aplastadac1_2); 
            potenciac1_2= bandpower(filtradac1_2,Fs,[8 13]);
            FeatureVector_c1_f2(j_2,lim_1_vect(:,a_2):lim_2_vect(:,a_2))=potenciac1_2;
         end
    end 
    
    FeatureVector_c1_f3=zeros(8,80);
    for a_3=1:4
        c1_3=class1(:,limite_1(:,a_3):limite_2(:,a_3),:);
         for j_3=1:8
            electrodoc1_3= c1_3(j_3,:,:);
            aplastadac1_3= squeeze(electrodoc1_3); 
            filtradac1_3= filtfilt(d,aplastadac1_3);
            potenciac1_3= bandpower(filtradac1_3,Fs,[13 18]);
            FeatureVector_c1_f3(j_3,lim_1_vect(:,a_3):lim_2_vect(:,a_3))=potenciac1_3;
         end
    end 
    
    FeatureVector_class1=[FeatureVector_c1_f1; FeatureVector_c1_f2; FeatureVector_c1_f3];

    %   análisis de la clase 2
    
    FeatureVector_c2_f1=zeros(8,80);
    for b=1:4
        c2=class2(:,limite_1(:,b):limite_2(:,b),:);
         for k=1:8
            electrodoc2= c2(k,:,:);
            aplastadac2= squeeze(electrodoc2); 
            filtradac2= filtfilt(d,aplastadac2);
            potenciac2= bandpower(filtradac2,Fs,[5 10]);
            FeatureVector_c2_f1(k,lim_1_vect(:,b):lim_2_vect(:,b))=potenciac2;
         end
    end 
    
    FeatureVector_c2_f2=zeros(8,80);
    for b_2=1:4
        c2_2=class2(:,limite_1(:,b_2):limite_2(:,b_2),:);
         for k_2=1:8
            electrodoc2_2= c2_2(k_2,:,:);
            aplastadac2_2= squeeze(electrodoc2_2); 
            filtradac2_2= filtfilt(d,aplastadac2_2);
            potenciac2_2= bandpower(filtradac2_2,Fs,[8 13]);
            FeatureVector_c2_f2(k_2,lim_1_vect(:,b_2):lim_2_vect(:,b_2))=potenciac2_2;
         end
    end 
    
    FeatureVector_c2_f3=zeros(8,80);
    for b_3=1:4
        c2_3=class2(:,limite_1(:,b_3):limite_2(:,b_3),:);
         for k_3=1:8
            electrodoc2_3= c2_3(k_3,:,:);
            aplastadac2_3= squeeze(electrodoc2_3); 
            filtradac2_3= filtfilt(d,aplastadac2_3);
            potenciac2_3= bandpower(filtradac2_3,Fs,[13 18]);
            FeatureVector_c2_f3(k_3,lim_1_vect(:,b_3):lim_2_vect(:,b_3))=potenciac2_3;
         end
    end 
    
    FeatureVector_class2=[FeatureVector_c2_f1; FeatureVector_c2_f2; FeatureVector_c2_f3];
    
    
    %   análisis de la clase 3
 
    
    FeatureVector_c3_f1=zeros(8,80);
    for e=1:4
        c3=class3(:,limite_1(:,e):limite_2(:,e),:);
         for m=1:8
            electrodoc3= c3(m,:,:);
            aplastadac3= squeeze(electrodoc3); 
            filtradac3= filtfilt(d,aplastadac3);
            potenciac3= bandpower(filtradac3,Fs,[5 10]);
            FeatureVector_c3_f1(m,lim_1_vect(:,e):lim_2_vect(:,e))=potenciac3;
         end
    end 
    
    FeatureVector_c3_f2=zeros(8,80);
    for e_2=1:4
        c3_2=class3(:,limite_1(:,e_2):limite_2(:,e_2),:);
         for m_2=1:8
            electrodoc3_2= c3_2(m_2,:,:);
            aplastadac3_2= squeeze(electrodoc3_2); 
            filtradac3_2= filtfilt(d,aplastadac3_2);
            potenciac3_2= bandpower(filtradac3_2,Fs,[8 13]);
            FeatureVector_c3_f2(m_2,lim_1_vect(:,e_2):lim_2_vect(:,e_2))=potenciac3_2;
         end
    end 
    
    FeatureVector_c3_f3=zeros(8,80);
    for e_3=1:4
        c3_3=class3(:,limite_1(:,e_3):limite_2(:,e_3),:);
         for m_3=1:8
            electrodoc3_3= c3_3(m_3,:,:);
            aplastadac3_3= squeeze(electrodoc3_3); 
            filtradac3_3= filtfilt(d,aplastadac3_3);
            potenciac3_3= bandpower(filtradac3_3,Fs,[13 18]);
            FeatureVector_c3_f3(m_3,lim_1_vect(:,e_3):lim_2_vect(:,e_3))=potenciac3_3;
         end
    end 
    
    FeatureVector_class3=[FeatureVector_c3_f1; FeatureVector_c3_f2; FeatureVector_c3_f3];
            
    labels= categorical(repelem(["Class a", "Class b"], 80));
    
    class1_class2= [FeatureVector_class1, FeatureVector_class2]';
    class1_class3= [FeatureVector_class1, FeatureVector_class3]';
    class2_class3= [FeatureVector_class2, FeatureVector_class3]';
    
    fprintf('----------------------------------\n');

    % escoger canales para c1 y c2
    idx= fscmrmr (class1_class2, labels); topidx= idx(1:3);
    best_c1c2= info_electrodos_frecuencias(topidx);
    mejores_c1c2 = class1_class2(:, topidx);
    fprintf('Los electrodos para la clase 1 y 2 son: %s\n', best_c1c2);
    fprintf('\n');
    bandas_c1c2= which_band(topidx);
   
    % escoger canales para c1 y c3
    idx_2= fscmrmr (class1_class3, labels); topidx_2= idx_2(1:3);
    best_c1c3= info_electrodos_frecuencias(topidx_2);
    mejores_c1c3 = class1_class3(:, topidx_2); 
    fprintf('Los electrodos para la clase 1 y 3 son: %s\n',  best_c1c3);
    fprintf('\n');
    bandas_c1c3= which_band(topidx_2);
    
    % escoger canales para c2 y c3
    idx_3= fscmrmr (class2_class3, labels); topidx_3= idx_3(1:3);
    best_c2c3= info_electrodos_frecuencias(topidx_3);
    mejores_c2c3 = class2_class3(:, topidx_3);
    fprintf('Los electrodos para la clase 2 y 3 son: %s\n', best_c2c3);
    fprintf('----------------------------------\n');
    bandas_c2c3= which_band(topidx_3);
    
    % división de características - 75% entrenamiento, 15% validación
    entrenamiento1= mejores_c1c2([1:60 81:140],:);
    clasificacion1= mejores_c1c2([61:80 141:160],:);
    
    entrenamiento2= mejores_c1c3([1:60 81:140],:);
    clasificacion2= mejores_c1c3([61:80 141:160],:);
    
    entrenamiento3= mejores_c2c3([1:60 81:140],:);
    clasificacion3= mejores_c2c3([61:80 141:160],:);
        
    etiquetas_entrenamiento=strings(120,1);
    etiquetas_entrenamiento(1:60, 1)="Clase a";
    etiquetas_entrenamiento(61:120, 1)="Clase b";
    
    etiquetas_clasificacion=strings(40,1);
    etiquetas_clasificacion(1:20, 1)="Clase a";
    etiquetas_clasificacion(21:40, 1)="Clase b";
    
    % para c1 y c2
    % generar los diferentes modelos de Máquinas de Soporte Vectorial
    mdl1_c1c2= fitcsvm(entrenamiento1, etiquetas_entrenamiento, 'KernelFunction', 'linear');
    mdl2_c1c2= fitcsvm(entrenamiento1, etiquetas_entrenamiento, 'KernelFunction', 'polynomial', 'PolynomialOrder', 2);
    mdl3_c1c2= fitcsvm(entrenamiento1, etiquetas_entrenamiento, 'KernelFunction', 'polynomial', 'PolynomialOrder', 3);
    mdl4_c1c2= fitcsvm(entrenamiento1, etiquetas_entrenamiento, 'KernelFunction', 'rbf');
    
    pred1_c1c2 = predict(mdl1_c1c2, clasificacion1);
    pred2_c1c2 = predict(mdl2_c1c2, clasificacion1);
    pred3_c1c2 = predict(mdl3_c1c2, clasificacion1);
    pred4_c1c2 = predict(mdl4_c1c2, clasificacion1);
    
    accuracymdl1_c1c2 = sum(pred1_c1c2 == etiquetas_clasificacion) / length(clasificacion1) * 100;
    accuracymdl2_c1c2 = sum(pred2_c1c2 == etiquetas_clasificacion) / length(clasificacion1) * 100;
    accuracymdl3_c1c2 = sum(pred3_c1c2 == etiquetas_clasificacion) / length(clasificacion1) * 100;
    accuracymdl4_c1c2 = sum(pred4_c1c2 == etiquetas_clasificacion) / length(clasificacion1) * 100;
    [maxval_c1c2, imax_c1c2]= max([accuracymdl1_c1c2, accuracymdl2_c1c2, accuracymdl3_c1c2, accuracymdl4_c1c2]);
    

    if imax_c1c2==1
        file_name= sprintf('model_c1c2%s.mat',nombreUsuario); %agrega el nombre de usuario al del archivo
        save(file_name, 'mdl1_c1c2');
        fprintf('El mejor modelo para la clase 1 y 2 es linear SVM con un accuracy de %d\n', accuracymdl1_c1c2);
    elseif imax_c1c2==2
        file_name= sprintf('model_c1c2%s.mat',nombreUsuario );
        save(file_name, 'mdl2_c1c2');
        fprintf('El mejor modelo para la clase 1 y 2 es quadratic SVM con un accuracy de %d\n', accuracymdl2_c1c2);
    elseif imax_c1c2==3
        file_name= sprintf('model_c1c2%s.mat', nombreUsuario);
        save(file_name, 'mdl3_c1c2');
        fprintf('El mejor modelo para la clase 1 y 2 es cubic SVM con un accuracy de %d\n', accuracymdl3_c1c2);
    else 
        file_name= sprintf('model_c1c2%s.mat', nombreUsuario);
        save(file_name, 'mdl4_c1c2');
        fprintf('El mejor modelo para la clase 1 y 2 es gaussian SVM con un accuracy de %d\n', accuracymdl4_c1c2);
    end 
    
    % para c1 y c3
    % generar los diferentes modelos de Máquinas de Soporte Vectorial
    mdl1_c1c3= fitcsvm(entrenamiento2, etiquetas_entrenamiento, 'KernelFunction', 'linear');
    mdl2_c1c3= fitcsvm(entrenamiento2, etiquetas_entrenamiento, 'KernelFunction', 'polynomial', 'PolynomialOrder', 2);
    mdl3_c1c3= fitcsvm(entrenamiento2, etiquetas_entrenamiento, 'KernelFunction', 'polynomial', 'PolynomialOrder', 3);
    mdl4_c1c3= fitcsvm(entrenamiento2, etiquetas_entrenamiento, 'KernelFunction', 'rbf');
    
    pred1_c1c3 = predict(mdl1_c1c3, clasificacion2);
    pred2_c1c3= predict(mdl2_c1c3, clasificacion2);
    pred3_c1c3 = predict(mdl3_c1c3, clasificacion2);
    pred4_c1c3 = predict(mdl4_c1c3, clasificacion2);
    
    accuracymdl1_c1c3 = sum(pred1_c1c3 == etiquetas_clasificacion) / length(clasificacion2) * 100;
    accuracymdl2_c1c3 = sum(pred2_c1c3 == etiquetas_clasificacion) / length(clasificacion2) * 100;
    accuracymdl3_c1c3 = sum(pred3_c1c3 == etiquetas_clasificacion) / length(clasificacion2) * 100;
    accuracymdl4_c1c3 = sum(pred4_c1c3 == etiquetas_clasificacion) / length(clasificacion2) * 100;
    [maxval_c1c3, imax_c1c3]= max([accuracymdl1_c1c3, accuracymdl2_c1c3, accuracymdl3_c1c3, accuracymdl4_c1c3]);
    
    if imax_c1c3==1
        save(sprintf('model_c1c3_%s.mat', nombreUsuario), 'mdl1_c1c3');
        fprintf('El mejor modelo para la clase 1 y 3 es linear SVM con un accuracy de %d\n', accuracymdl1_c1c3);
    elseif imax_c1c3==2
        save(sprintf('model_c1c3%s.mat', nombreUsuario), 'mdl2_c1c3');
        fprintf('El mejor modelo para la clase 1 y 3 es quadratic SVM con un accuracy de %d\n', accuracymdl2_c1c3);
    elseif imax_c1c3==3
        save(sprintf('model_c1c3_%s.mat', nombreUsuario), 'mdl3_c1c3');
        fprintf('El mejor modelo para la clase 1 y 3 es cubic SVM con un accuracy de %d\n', accuracymdl3_c1c3);
    else 
        save(sprintf('model_c1c3_%s.mat', nombreUsuario), 'mdl4_c1c3');
        fprintf('El mejor modelo para la clase 1 y 3 es gaussian SVM con un accuracy de %d\n', accuracymdl4_c1c3);
    end 
    
    % para c2 y c3
    % generar los diferentes modelos de Máquinas de Soporte Vectorial
    mdl1_c2c3= fitcsvm(entrenamiento3, etiquetas_entrenamiento, 'KernelFunction', 'linear');
    mdl2_c2c3= fitcsvm(entrenamiento3, etiquetas_entrenamiento, 'KernelFunction', 'polynomial', 'PolynomialOrder', 2);
    mdl3_c2c3= fitcsvm(entrenamiento3, etiquetas_entrenamiento, 'KernelFunction', 'polynomial', 'PolynomialOrder', 3);
    mdl4_c2c3= fitcsvm(entrenamiento3, etiquetas_entrenamiento, 'KernelFunction', 'rbf');
    
    pred1_c2c3 = predict(mdl1_c2c3, clasificacion3);
    pred2_c2c3 = predict(mdl2_c2c3, clasificacion3);
    pred3_c2c3 = predict(mdl3_c2c3, clasificacion3);
    pred4_c2c3 = predict(mdl4_c2c3, clasificacion3);
    
    accuracymdl1_c2c3 = sum(pred1_c2c3 == etiquetas_clasificacion) / length(clasificacion3) * 100;
    accuracymdl2_c2c3 = sum(pred2_c2c3 == etiquetas_clasificacion) / length(clasificacion3) * 100;
    accuracymdl3_c2c3 = sum(pred3_c2c3 == etiquetas_clasificacion) / length(clasificacion3) * 100;
    accuracymdl4_c2c3 = sum(pred4_c2c3 == etiquetas_clasificacion) / length(clasificacion3) * 100;
    [maxval_c2c3, imax_c2c3]= max([accuracymdl1_c2c3, accuracymdl2_c2c3, accuracymdl3_c2c3, accuracymdl4_c2c3]);
    
    if imax_c2c3==1
        fprintf('El mejor modelo para la clase 2 y 3 es linear SVM con un accuracy de %d\n', accuracymdl1_c2c3);
    elseif imax_c2c3==2 
        fprintf('El mejor modelo para la clase 2 y 3 es quadratic SVM con un accuracy de %d\n', accuracymdl2_c2c3);
    elseif imax_c2c3==3
        fprintf('El mejor modelo para la clase 2 y 3 es cubic SVM con un accuracy de %d\n', accuracymdl3_c2c3);
    else 
        fprintf('El mejor modelo para la clase 2 y 3 es gaussian SVM con un accuracy de %d\n', accuracymdl4_c2c3);
    end 

    %crear un archivo donde se almacene la información de las frecuencias
    %junto con el archivo del modelo entrenado

    % para c1 y c2
    [~, imax_c1c2] = max([accuracymdl1_c1c2, accuracymdl2_c1c2, accuracymdl3_c1c2, accuracymdl4_c1c2]);
    % Selección del mejor modelo y su accuracy
    modelos_c1c2 = {mdl1_c1c2, mdl2_c1c2, mdl3_c1c2, mdl4_c1c2};
    bestModel    = modelos_c1c2{imax_c1c2};
    bestBandas   = bandas_c1c2;   
    bestChannels = best_c1c2;
    accs = [accuracymdl1_c1c2, accuracymdl2_c1c2, accuracymdl3_c1c2, accuracymdl4_c1c2];
    bestAcc = accs(imax_c1c2);    
    save(sprintf('model_c1c2_%s.mat', nombreUsuario), 'bestModel','bestBandas','bestAcc', 'bestChannels');

    % para c1 y c3
    [~, imax_c1c3] = max([accuracymdl1_c1c3, accuracymdl2_c1c3, accuracymdl3_c1c3, accuracymdl4_c1c3]);
    modelos_c1c3   = {mdl1_c1c3, mdl2_c1c3, mdl3_c1c3, mdl4_c1c3};
    bestModel      = modelos_c1c3{imax_c1c3};
    bestBandas     = bandas_c1c3;
    bestChannels   = best_c1c3;
    accs = [accuracymdl1_c1c3, accuracymdl2_c1c3, accuracymdl3_c1c3, accuracymdl4_c1c3];
    bestAcc = accs(imax_c1c3);    
    save(sprintf('model_c1c3_%s.mat', nombreUsuario), 'bestModel','bestBandas','bestAcc', 'bestChannels');
    
    % para c2 y c3
    [~, imax_c2c3] = max([accuracymdl1_c2c3, accuracymdl2_c2c3, accuracymdl3_c2c3, accuracymdl4_c2c3]);
    modelos_c2c3   = {mdl1_c2c3, mdl2_c2c3, mdl3_c2c3, mdl4_c2c3};
    bestModel      = modelos_c2c3{imax_c2c3};
    bestBandas     = bandas_c2c3;
    bestChannels   = best_c2c3;
    accs = [accuracymdl1_c2c3, accuracymdl2_c2c3, accuracymdl3_c2c3, accuracymdl4_c2c3];
    bestAcc = accs(imax_c2c3);    
    save(sprintf('model_c2c3_%s.mat', nombreUsuario), 'bestModel','bestBandas','bestAcc', 'bestChannels');

    % funcion para obtener las mejores bandas de frecuencia
    function banda= which_band(index)
        n = numel(index);
        banda = zeros(n,2);
        for w = 1:n
            if index(w) >= 1 && index(w) <= 8
            banda(w,:) = [5 10];
        elseif index(w) >= 9 && index(w) <= 16
            banda(w,:) = [8 13];
        elseif index(w) >= 17 && index(w) <= 24
            banda(w,:) = [13 18];
        else
            error('FUERA DE RANGO %d', index(w));
        end
    end
end
    
end

% *ESTA FUNCIÓN NO PUEDE SER USADA SIN LA APP app_entrenado_y_test.mlapp O
% SU CORRECTA IMPLEMENTACIÓN ALTERNATIVA