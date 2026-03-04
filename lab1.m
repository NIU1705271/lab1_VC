    
% tasca 1

files = dir('lab1\img\train\*.jpg');
img = imread("lab1\img\train\in001051.jpg");
img_grey = rgb2gray(img);

% tasca 2
folderPath = 'lab1\img\train'; 

all_images = cell(1, length(files));
all_images_grey = cell(1, length(files));

for i = 1 : length(files)
    path = fullfile(folderPath, files(i).name);
    all_images{i} = imread(path);
    all_images_grey{i} = rgb2gray(all_images{i});
end

matriu = double(cat(3,all_images_grey{:}));

imatge_mitjana_double = mean(matriu,3);
imatge_std_double = std(matriu,0,3);

imatge_mitjana = uint8(imatge_mitjana_double);
imatge_std = uint8(imatge_std_double);



% tasca 3

sumatori = sum(imatge_std);
mida = numel(imatge_std);
mitjana_total = sum(sumatori) / mida;
llindar = 1.1*mitjana_total;
imatge_std_senseFons = imatge_std>llindar;


    
% tasca 4
%{
diferencia = cell(1, length(all_images_grey));
mask_elaborat = cell(1, length(all_images_grey)); 

alpha = [1.5];
beta = [12];
for a = alpha
    for b = beta
        for k = 1:length(all_images_grey)
            % 1. Use 'k' to get the current image
            img_gray_double = double(all_images_grey{k}); 
            
            % 2. Remove '(k)' to subtract the whole matrix, and use the 'double' mean
            diferencia{k} = abs(img_gray_double - imatge_mitjana_double); 
            
            % 3. Use 'k' and the 'double' std matrix for accurate thresholding
            mask_elaborat{k} = diferencia{k} > (a * imatge_std_double + b);

        end
    end
end
%}



tasca = input("Tasca a executar:");

switch tasca
    case 1
        
    case 2
        figure;
        subplot(1,2,1); imshow(imatge_mitjana); title('Mitjana (amb mean)');
        subplot(1,2,2); imshow(imatge_std); title('Std (amb std)');
    case 3
        num_imatges = 10;

        total_imatges = length(files); 
        
        indexs_aleatoris = randperm(total_imatges, num_imatges);
        
        imatges_mostra = cell(1, num_imatges);
        imatges_finals = cell(1, num_imatges);

        
        for i = 1:num_imatges
            idx_triat = indexs_aleatoris(i);
            imatges_mostra{i} = all_images_grey{idx_triat};

            matriu = double(cat(3,imatges_mostra{i}));

            mostra_std_double = std(matriu,0,3);
            mostra_std = uint8(imatge_std_double);

            mask = mostra_std>llindar;
            imatges_finals{i}=imatges_mostra{i}.*uint8(imatge_std_senseFons);
            
            figure;

            subplot(1, 2, 1); 
            imshow(imatges_mostra{i});
            title('Imatge Original (Grisos)');
            
            subplot(1, 2, 2); 
            imshow(imatges_finals{i});
            title('Cotxe Aïllat (Fons Negre)');
        end
        
        

    case 4

        num_imatges = 5;
        total_imatges = length(files); 
        
        % Triem les 5 imatges aleatòries UNA vegada per poder comparar
        indexs_aleatoris = randperm(total_imatges, num_imatges);
        
        alpha = [1];
        beta = [6];
        
        se_neteja = strel('disk', 0);
        se_omplir = strel('disk', 0);

        % Iterem per cada valor d'alpha i beta
        for a = alpha
            for b = beta
                
                % Creem una nova finestra per a cada combinació amb un títol clar
                figure('Name', sprintf('Resultats per Alpha = %.1f, Beta = %.1f', a, b), 'NumberTitle', 'off');
                
                for i = 1:num_imatges
                    idx_triat = indexs_aleatoris(i);
                    img_original = all_images_grey{idx_triat};
            
                    % Calculem la diferència només per a la imatge actual (convertida a double)
                    img_gray_double = double(img_original);
                    diferencia_act = abs(img_gray_double - imatge_mitjana_double);
            
                    % Apliquem el llindar amb els valors 'a' i 'b' actuals del bucle
                    mask_elaborat_act = diferencia_act > (a * imatge_std_double + b);
                   
                    mask_neta = imopen(mask_elaborat_act, se_neteja);
            
                    % b) imclose: Omple petits forats negres dins de les taques blanques
                    mask_neta = imclose(mask_neta, se_omplir);
                  
                    % Multipliquem la màscara per la imatge original
                    img_final = img_original .* uint8(mask_neta);            
                    
                    % --- Dibuixem els subplots en una graella de 5 files x 2 columnes ---
                    
                    % 1a Columna: Imatge Original
                    subplot(5, 2, 2*i - 1); 
                    imshow(img_original);
                    if i == 1 % Posem el títol només a la primera fila
                        title('Imatge Original');
                    end
                    
                    % 2a Columna: Cotxe Aïllat
                    subplot(5, 2, 2*i); 
                    imshow(mask_neta);
                    if i == 1 % Posem el títol només a la primera fila
                        title(sprintf('Aïllat (\\alpha=%.1f, \\beta=%.1f)', a, b));
                    end
                end
                
            end
        end

    case 5

        millor_alpha = 1; 
        millor_beta = 6;
        
        % 2. Creem l'element estructurant (la "forma" que usem per netejar)
        % Un disc de radi 3 o 4 sol funcionar molt bé per a aquesta tasca
        se_neteja = strel('disk', 2);
        se_omplir = strel('disk', 6);
        
        % 3. Preparem l'arxiu de vídeo
        video_filename = 'resultat_cotxes.mp4';
        v = VideoWriter(video_filename, 'MPEG-4');
        v.FrameRate = 15; % Fotogrames per segon (ajusta si va molt ràpid o lent)
        open(v);
        
        % 4. Iterem per TOTES les imatges de la carpeta
        for k = 1:length(all_images_grey)
            % Convertim a double per fer la resta
            img_gray_double = double(all_images_grey{k});
            
            % Obtenim la màscara bruta (com a la tasca 4)
            diferencia_act = abs(img_gray_double - imatge_mitjana_double);
            mask_bruta = diferencia_act > (millor_alpha * imatge_std_double + millor_beta);
            
            % --- OPERACIONS MORFOLÒGIQUES ---
            % a) imopen: Elimina petits punts blancs aïllats (soroll)
            mask_neta = imopen(mask_bruta, se_neteja);
            
            % b) imclose: Omple petits forats negres dins de les taques blanques
            mask_neta = imclose(mask_neta, se_omplir);
            
            % --- GRAVACIÓ DEL FRAME ---
            % Convertim la màscara lògica (0 i 1) a imatge visible (0 i 255)
            frame_video = uint8(mask_neta) * 255; 
            
            % Escrivim el frame al vídeo
            writeVideo(v, frame_video);
        end
        
        % Tanquem i desem l'arxiu
        close(v);

    case 6
        % --- 1. RUTES A LES CARPETES (Canvia-ho si cal!) ---
        folder_test = 'lab1\img\test'; 
        folder_gt = 'lab1\img\groundtruth'; 
        
        files_test = dir(fullfile(folder_test, '*.jpg'));
        files_gt = dir(fullfile(folder_gt, '*.png'));
        num_imatges_test = length(files_test);
        
        % --- 2. RANGS A EXPLORAR ---
        % Alpha entre 1 i 3 (amb salts de 0.5)
        alphas_test = 1:0.5:5;
        % Beta entre 2 i 8 (amb salts de 1)
        betas_test = 2:1:12;
        
        % Matriu per guardar l'Accuracy acumulada per cada combinació
        accuracies_grid = zeros(length(alphas_test), length(betas_test));
        
        % --- 3. BUCLE DE CERCA DELS MILLORS PARÀMETRES ---
        disp('Explorant combinacions d''alpha i beta (llegint imatges)...');
        
        for i = 1:num_imatges_test
            % 3.1. Llegim la imatge de test i de Ground Truth UNA SOLA VEGADA
            img_test = double(rgb2gray(imread(fullfile(folder_test, files_test(i).name))));
            gt_img = imread(fullfile(folder_gt, files_gt(i).name));
            
            % El Ground Truth: 255 normalment són els vehicles.
            mask_gt = (gt_img == 255); 
            
            % Calculem la diferència base
            diferencia = abs(img_test - imatge_mitjana_double);
            
            % 3.2. Provem tots els alphas i betas sobre AQUESTA imatge
            for idx_a = 1:length(alphas_test)
                a = alphas_test(idx_a);
                for idx_b = 1:length(betas_test)
                    b = betas_test(idx_b);
                    
                    % Calculem màscara i accuracy
                    mask_pred = diferencia > (a * imatge_std_double + b);
                    acc = sum(mask_pred(:) == mask_gt(:)) / numel(mask_gt);
                    
                    % Ho sumem a la casella corresponent de la matriu
                    accuracies_grid(idx_a, idx_b) = accuracies_grid(idx_a, idx_b) + acc;
                end
            end
        end
        
        % Fem la mitjana dividint pel total d'imatges
        accuracies_grid = accuracies_grid / num_imatges_test;
        
        % --- 4. TROBAR EL MÀXIM ---
        [max_acc, linear_idx] = max(accuracies_grid(:));
        [best_idx_a, best_idx_b] = ind2sub(size(accuracies_grid), linear_idx);
        
        best_alpha = alphas_test(best_idx_a);
        best_beta = betas_test(best_idx_b);
        
        fprintf('\n--- MILLORS PARÀMETRES TROBATS ---\n');
        fprintf('Alpha òptim: %.1f\n', best_alpha);
        fprintf('Beta òptim : %.1f\n', best_beta);
        fprintf('Accuracy   : %.2f%%\n\n', max_acc * 100);
        
        % --- 5. CÀLCUL DELS 3 CASOS AMB ELS PARÀMETRES ÒPTIMS ---
        disp('Calculant els 3 casos amb aquests paràmetres òptims...');
        
        acc_cas1 = zeros(1, num_imatges_test);
        acc_cas2 = zeros(1, num_imatges_test);
        acc_cas3 = zeros(1, num_imatges_test);
        
        se_neteja = strel('disk', 3);
        se_omplir = strel('disk', 5);
        
        % Definim uns paràmetres "Estrictes" (Cas 2) basats en els millors però més alts
        strict_alpha = best_alpha + 1.5;
        strict_beta  = best_beta + 2.0;
        
        for i = 1:num_imatges_test
            img_test = double(rgb2gray(imread(fullfile(folder_test, files_test(i).name))));
            gt_img = imread(fullfile(folder_gt, files_gt(i).name));
            mask_gt = (gt_img == 255);
            diferencia = abs(img_test - imatge_mitjana_double);
            
            % CAS 1: Base (Els millors paràmetres trobats)
            mask_cas1 = diferencia > (best_alpha * imatge_std_double + best_beta);
            acc_cas1(i) = sum(mask_cas1(:) == mask_gt(:)) / numel(mask_gt);
            
            % CAS 2: Estricte (Valors alts per veure si empitjora o millora)
            mask_cas2 = diferencia > (strict_alpha * imatge_std_double + strict_beta);
            acc_cas2(i) = sum(mask_cas2(:) == mask_gt(:)) / numel(mask_gt);
            
            % CAS 3: Morfologia (Els millors paràmetres + imopen/imclose)
            mask_cas3 = imopen(mask_cas1, se_neteja);
            mask_cas3 = imclose(mask_cas3, se_omplir);
            acc_cas3(i) = sum(mask_cas3(:) == mask_gt(:)) / numel(mask_gt);
        end
        
        % --- 6. MOSTRAR RESULTATS DELS 3 CASOS ---
        fprintf('\n--- RESULTATS DELS 3 CASOS CONCRETS ---\n');
        fprintf('Cas 1 (Base òptima: a=%.1f, b=%.1f) : %.2f %%\n', best_alpha, best_beta, mean(acc_cas1) * 100);
        fprintf('Cas 2 (Estricte: a=%.1f, b=%.1f)      : %.2f %%\n', strict_alpha, strict_beta, mean(acc_cas2) * 100);
        fprintf('Cas 3 (Cas 1 + Morfologia)            : %.2f %%\n', mean(acc_cas3) * 100);
        disp('---------------------------------------------');

    case 7
        % --- 1. RUTES A LES CARPETES (Canvia-ho si cal!) ---
        folder_test = 'lab1\img\test'; 
        folder_gt = 'lab1\img\groundtruth'; 
        
        files_test = dir(fullfile(folder_test, '*.jpg'));
        files_gt = dir(fullfile(folder_gt, '*.png'));
        num_imatges_test = length(files_test);
        
        alphas_test = 1:0.5:3;     % 5 valors: 1.0, 1.5, 2.0, 2.5, 3.0
        betas_test = 2:2:8;        % 4 valors: 2, 4, 6, 8
        radis_neteja = 1:3;        % 3 valors: 1, 2, 3 (pel filtre imopen)
        radis_omplir = 2:2:6;      % 3 valors: 2, 4, 6 (pel filtre imclose)
        
        % Matriu 4D per guardar les precisions de les 180 combinacions possibles
        accuracies_grid = zeros(length(alphas_test), length(betas_test), length(radis_neteja), length(radis_omplir));
        
        % --- 3. BUCLE DE CERCA DELS MILLORS PARÀMETRES ---
        for i = 1:num_imatges_test
            % Llegim imatge i GT
            img_test = double(rgb2gray(imread(fullfile(folder_test, files_test(i).name))));
            gt_img = imread(fullfile(folder_gt, files_gt(i).name));
            mask_gt = (gt_img == 255); % Adaptar si els vehicles no són 255
            
            diferencia = abs(img_test - imatge_mitjana_double);
            
            % Bucle 4D
            for idx_a = 1:length(alphas_test)
                a = alphas_test(idx_a);
                for idx_b = 1:length(betas_test)
                    b = betas_test(idx_b);
                    
                    % 1r pas: Calcular màscara base sense filtres
                    mask_base = diferencia > (a * imatge_std_double + b);
                    
                    for idx_rn = 1:length(radis_neteja)
                        rn = radis_neteja(idx_rn);
                        se_neteja = strel('disk', rn);
                        
                        % 2n pas: Netejar (imopen)
                        mask_neta = imopen(mask_base, se_neteja);
                        
                        for idx_ro = 1:length(radis_omplir)
                            ro = radis_omplir(idx_ro);
                            se_omplir = strel('disk', ro);
                            
                            % 3r pas: Omplir (imclose)
                            mask_final = imclose(mask_neta, se_omplir);
                            
                            % 4t pas: Calcular Accuracy i sumar-la a la matriu
                            acc = sum(mask_final(:) == mask_gt(:)) / numel(mask_gt);
                            accuracies_grid(idx_a, idx_b, idx_rn, idx_ro) = accuracies_grid(idx_a, idx_b, idx_rn, idx_ro) + acc;
                        end
                    end
                end
            end
            
            % Mostrar per consola el progrés cada 10 imatges
            if mod(i, 10) == 0
                fprintf('  Processades %d de %d imatges...\n', i, num_imatges_test);
            end
        end
        
        % Fem la mitjana global dividint pel total d'imatges
        accuracies_grid = accuracies_grid / num_imatges_test;
        
        % --- 4. TROBAR EL MÀXIM DINS LA MATRIU 4D ---
        [max_acc, linear_idx] = max(accuracies_grid(:));
        [best_idx_a, best_idx_b, best_idx_rn, best_idx_ro] = ind2sub(size(accuracies_grid), linear_idx);
        
        best_alpha = alphas_test(best_idx_a);
        best_beta = betas_test(best_idx_b);
        best_rn = radis_neteja(best_idx_rn);
        best_ro = radis_omplir(best_idx_ro);
        
        fprintf('\n🏆 --- MILLORS PARÀMETRES TROBATS --- 🏆\n');
        fprintf('Alpha òptim       : %.1f\n', best_alpha);
        fprintf('Beta òptim        : %.1f\n', best_beta);
        fprintf('Radi Neteja òptim : %d\n', best_rn);
        fprintf('Radi Omplir òptim : %d\n', best_ro);
        fprintf('Accuracy Màxima   : %.2f%%\n\n', max_acc * 100);
        
        % --- 5. CÀLCUL DELS 3 CASOS FINALS (Avaluació) ---
        disp('Generant les mètriques per als 3 casos requerits a la memòria...');
        
        acc_cas1 = zeros(1, num_imatges_test);
        acc_cas2 = zeros(1, num_imatges_test);
        acc_cas3 = zeros(1, num_imatges_test);
        
        % Elements estructurants per defecte i exagerats
        se_neteja_optim = strel('disk', best_rn);
        se_omplir_optim = strel('disk', best_ro);
        
        se_exagerat = strel('disk', best_ro + 5); % Un filtre massa gran a propòsit
        
        for i = 1:num_imatges_test
            img_test = double(rgb2gray(imread(fullfile(folder_test, files_test(i).name))));
            gt_img = imread(fullfile(folder_gt, files_gt(i).name));
            mask_gt = (gt_img == 255);
            diferencia = abs(img_test - imatge_mitjana_double);
            
            % --- Màscara base amb els millors Alpha i Beta ---
            mask_base_optima = diferencia > (best_alpha * imatge_std_double + best_beta);
            
            % CAS 1: Només els millors Alpha i Beta (SENSE filtres morfològics)
            acc_cas1(i) = sum(mask_base_optima(:) == mask_gt(:)) / numel(mask_gt);
            
            % CAS 2: El resultat ÒPTIM SUPERIOR (Millors a/b + Millors filtres)
            mask_cas2 = imopen(mask_base_optima, se_neteja_optim);
            mask_cas2 = imclose(mask_cas2, se_omplir_optim);
            acc_cas2(i) = sum(mask_cas2(:) == mask_gt(:)) / numel(mask_gt);
            
            % CAS 3: Valors òptims però aplicant un filtre exagerat per veure com empitjora
            mask_cas3 = imopen(mask_base_optima, se_exagerat);
            mask_cas3 = imclose(mask_cas3, se_exagerat);
            acc_cas3(i) = sum(mask_cas3(:) == mask_gt(:)) / numel(mask_gt);
        end
        
        % --- 6. MOSTRAR RESULTATS DELS 3 CASOS ---
        fprintf('\n📊 --- RESULTATS DELS 3 CASOS CONCRETS --- 📊\n');
        fprintf('Cas 1 (Sense Filtres: a=%.1f, b=%.1f)                     : %.2f %%\n', best_alpha, best_beta, mean(acc_cas1) * 100);
        fprintf('Cas 2 (Òptim absolut: + Neteja=%d, Omplir=%d)            : %.2f %% (Aquesta ha de ser la més alta!)\n', best_rn, best_ro, mean(acc_cas2) * 100);
        fprintf('Cas 3 (Filtre Exagerat: Radi %d - per demostrar errors)  : %.2f %%\n', best_ro + 5, mean(acc_cas3) * 100);
        disp('---------------------------------------------');
end