%% Función para la clasificación en tiempo real de señales EEG en una BCI
% Elaborado por: Karla González Cabrales, karla.gonzalezcs@udlap.mx
%
% Esta función adquiere señales EEG en tiempo real, extrae características
% a partir de canales y bandas de frecuencia previamente
% seleccionados, y utiliza un modelo de clasificación entrenado para
% predecir la clase correspondiente a cada intención del usuario.
%
% Esta función envía un comando a un dispositivo mediante un enlace por
% dirección IP, se recomienda que este sea un Arduino. Además, permite al 
% usuario proporcionar retroalimentación sobre si la acción ejecutada fue 
% correcta o incorrecta.
%
% PARÁMETROS DE ENTRADA PROPORCIONADOS POR EL USUARIO:
% IP               : dirección IP del dispositivo externo.
% port             : puerto COM asociado al dongle del casco EEG.
% modelPath        : seleccción del archivo .mat que contiene el modelo entrenado.
% freq             : matriz de bandas de frecuencia seleccionadas para cada
%                    característica.
% electrodos       : vector con los índices de los electrodos seleccionados
%                    para la clasificación.
% nombreUsuario    : nombre del usuario.
% - El resto de parámetros son definidos automáticamente por la aplicación.
% 
% PARÁMETROS DE SALIDA:
% results    : vector con las predicciones realizadas en cada iteración.
% raw_data   : matriz con fragmentos de señal almacenados para posible
%              análisis posterior o retroalimentación.
% raw_labels : etiquetas asociadas a los datos almacenados en raw_data.
% - Al finalizar, se genera un archivo con dicha información con el nombre 
% 'real_time_nombreUsuario.mat'
%
% - El modelo cargado debe contener la variable bestModel.
% - Se utilizan únicamente los 3 electrodos previamente seleccionados.
% 
% RETROALIMENTACIÓN DEL USUARIO:
% - Después de cada acción, el usuario indica si la accioón fue correcta o
% incorrecta, esta información es usada para almacenar la señal y sus
% etiquetas.
% - Una vez que el usuario brinde la retroalimentación, el sistema empieza
% de nuevo con la captura de EEG.
%
% - Esta función depende de una correcta configuración del casco EEG, del 
% modelo previamente entrenado y del dispositivo Arduino conectado.

function[results, raw_data, raw_labels]= real_time_brainflow (IP, port, modelPath, freq, electrodos, contador, ResponseProvider,nombreUsuario)
    
    if nargin < 7 || isempty(ResponseProvider) % cambio de 6 a 7, 6 de abril
        ResponseProvider = @(prompt) input(prompt, 's');
    end

    BoardShim.set_log_file('brainflow.log');
    BoardShim.enable_dev_board_logger();
    
    params = BrainFlowInputParams();
    params.serial_port = port;
    board_shim = BoardShim(int32(BoardIds.CYTON_BOARD), params);
    preset = int32(BrainFlowPresets.DEFAULT_PRESET); 
    board_shim.get_analog_channels(0,preset)
    board_shim.get_board_presets(0)
    % Preparación e inicio del flujo de datos en tiempo real
    board_shim.prepare_session();
    board_shim.start_stream(2000, ''); % antes 5000
    pause(0.5)
    
    Wp1=5;  
    Wp2=30; 
    Fs=250; 
    vector = electrodos;

    % Comunicación TCP/IP con el Arduino
    arduinoIP= IP;
    arduinoPort = 5000; % Puerto TCP definido en el código de arduino (fijo)
    disp('Conectando con el Arduino...');
    device = tcpclient(arduinoIP, arduinoPort);
    disp('Conexión establecida.');

    nombreUsuario= regexprep(nombreUsuario, '\W', '_');

    d= designfilt('bandpassiir','Filterorder', 6, 'HalfPowerFrequency1',Wp1,'HalfPowerFrequency2',Wp2, ...
        'SampleRate',Fs);

    S= load(modelPath);
    if isfield(S,'bestModel')
        model = S.bestModel;
    else
        error('El archivo no tiene la variable bestModel.');
    end

    results= strings(0);
    count= 0;
    raw_data=[];
    raw_labels=[];
    
    % Bucle principal de clasificación en tiempo real
    while count < contador % 20 eventos (definidos dentro de la app)
    
        pause(4);
        valores = board_shim.get_current_board_data(1000, preset);
        count = count + 1;
    
        FV= zeros(1,3); % vector para clasificación
        for ch= 1:3
            filtered= filtfilt(d, valores(vector(ch),:)); % filtra cada ventana
            FV(ch)=bandpower(filtered, Fs, freq(ch,:)); % obtiene la característica
            
        end 
        prediction= predict(model, FV); 
        results = [results, prediction]; % almacenar los resutados
        
        if prediction == "Clase a"
            write(device,'F', 'char'); % escribir F por el COM (forward)
            disp('clase a (0)');
            disp('clase a')
            pause (7); 
            disp('Was this the correct action?')

            user_response= ResponseProvider('Was this the correct action? Press "c" for Correct or "i" for Incorrect: ');
            if strcmp(user_response, 'c')
                raw_data= [raw_data, valores(1:3,251:1000)]; % almacenar los datos
                label= 0;
                raw_labels= [raw_labels, label];
            elseif strcmp(user_response, 'i')
                raw_data= [raw_data, valores(1:3,251:1000)]; % almacenar los datos
                label= 1;
                raw_labels= [raw_labels, label];
            else
                disp('Not a valid response, program will continue now...');
                pause (3);
            end
            
        elseif prediction == "Clase b"
            write(device,'B','char'); %escribir B por el COM (backwards)
            disp('clase b (1)');
            disp('clase b');
            pause (7); 
            disp('Was this the correct action?')

            user_response= ResponseProvider('Was this the correct action? Press "c" for Correct or "i" for Incorrect: ');

            if strcmp(user_response, 'c')
                raw_data= [raw_data, valores(1:3,251:1000)]; % almacenar los datos
                label= 1;
                raw_labels= [raw_labels, label];
            elseif strcmp(user_response, 'i')
                raw_data= [raw_data, valores(1:3,251:1000)]; % almacenar los datos
                label= 0;
                raw_labels= [raw_labels, label];
            else
                disp('Not a valid response, program will continue now...');
                pause (3);
            end
        else
            disp('NADA');
        end

    end
    
    
    board_shim.stop_stream();
    board_shim.release_session();

   save(sprintf('real_time_%s.mat',nombreUsuario), 'results', "raw_labels", "raw_data");

   clear device % cerrar comunicación


end 


% *ESTA FUNCIÓN NO PUEDE SER USADA SIN LA APP app_entrenado_y_test.mlapp O
% SU CORRECTA IMPLEMENTACIÓN ALTERNATIVA
% - La función está configurada para trabajar con la tarjeta Cyton OpenBCI.
