%% Función para la captura inicial de estímulos de BCI
% Elaborado por: Karla González Cabrales, karla.gonzalezcs@udlap.mx
%
% PARÁMETROS DE ENTRADA PROPORCIONADOS POR EL USUARIO:
% port: puerto COM asociado al dongle del casco EEG.
% - El resto de parámetros son definidos automáticamente por la aplicación.
%
% Como PARÁMETRO DE SALIDA, la función genera el vector de la señal
% adquirida, un vector de etiquetas y la frecuencia de muestreo.
% Etiquetas correspondientes:
%   1 = derecha
%   2 = izquierda
%   3 = imagine
% 
% Si se requiere CAMBIAR LAS IMÁGENES utilizadas en la interfaz, se debe
% modificar la instrucción correspondiente:
% showFcn(fullfile(path_folder,'nombre_de_la_imagen.ext'));
% 
% otros parámetros importantes:
% n=10; --------- 10 repeticiones por estímulo, dando un total de 30 estímulos.
% win = 1250; --- muestras capturadas por cada estímulo.


function [signal, s, Fs] = entrena_bci(port, showFcn, path_folder)
    BoardShim.set_log_file('brainflow.log');
    BoardShim.enable_dev_board_logger();
    params = BrainFlowInputParams();
    params.serial_port = string(port);
    board_shim = BoardShim(int32(BoardIds.CYTON_BOARD), params);
    preset = int32(BrainFlowPresets.DEFAULT_PRESET);

    eeg_chan=board_shim.get_eeg_channels(0,preset);
    chan_names=board_shim.get_eeg_names(0,preset);
    board_shim.get_board_presets(0)
    num_chan_eeg=length(eeg_chan);
    Fs=double(board_shim.get_sampling_rate(0,preset));

    
    board_shim.prepare_session();
    board_shim.start_stream(3000, '');

    n=10;
    win=1250;
    s=[ones(1,n) ones(1,n)*2 ones(1,n)*3];
    index=randperm(3*n);
    s=s(index);

    showFcn(fullfile(path_folder,'start.jpg'));
    pause(5)
    for i=1:3*n
        if s(i)==1
            showFcn(fullfile(path_folder,'derecha.jpg'));
        elseif s(i)==2
            showFcn(fullfile(path_folder,'izquierda.jpg'));
        else
            showFcn(fullfile(path_folder,'imagine.jpg'));
            
        end
        pause(8);
        data = board_shim.get_current_board_data(win, preset); 
        signal(:,:,i)=data(eeg_chan,:);
        t=rand(1)+3.5;
        showFcn(fullfile(path_folder,'blank.jpg'));
        pause(t)
    end
    board_shim.stop_stream();
    board_shim.release_session();
end 

% *ESTA FUNCIÓN NO PUEDE SER USADA SIN LA APP
% app_toma_de_registros_iniciales.mlapp O SU CORRECTA IMPLEMENTACIÓN
% ALTERNATIVA
% - La función está configurada para trabajar con la tarjeta Cyton OpenBCI.

