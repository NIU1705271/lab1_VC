% VC/PSIV - Lab 1: Detecció de vehicles
clear; clc; close all;

base_dir = fullfile('highway');
input_dir = fullfile(base_dir, 'input');           
gt_dir = fullfile(base_dir, 'groundtruth');

idx_start = 1051;
num_train = 150;
num_test = 150;

%% Tasca 1: Carregar dades
img_ref = rgb2gray(imread(fullfile(input_dir, sprintf('in%06d.jpg', idx_start))));
[rows, cols] = size(img_ref);

train_images = zeros(rows, cols, num_train, 'double');

for i = 1:num_train
    img_idx = idx_start + i - 1;
    img_path = fullfile(input_dir, sprintf('in%06d.jpg', img_idx));
    train_images(:,:,i) = double(rgb2gray(imread(img_path)));
end

%% Tasca 2: Model de fons (mitjana i std)
mu = mean(train_images, 3);
sigma = std(train_images, 0, 3);

figure('Name', 'Tasca 2');
subplot(1,2,1); imshow(uint8(mu)); title('Mitjana');
subplot(1,2,2); imshow(sigma, [0, max(sigma(:))]); colormap gray; title('Desviació Estàndard');

%% Tasca 3 i 4: Segmentació simple i elaborada
alpha = 1.0; 
beta = 8;
thr_simple = 50; 

img_idx_test = idx_start + num_test; % Frame 1201
img_test = double(rgb2gray(imread(fullfile(input_dir, sprintf('in%06d.jpg', img_idx_test)))));

mask_simple = abs(img_test - mu) > thr_simple;
mask_elaborat = abs(img_test - mu) > (alpha * sigma + beta);

figure('Name', 'Tasques 3 i 4');
subplot(1,3,1); imshow(uint8(img_test)); title('Original');
subplot(1,3,2); imshow(mask_simple); title('T3: Simple');
subplot(1,3,3); imshow(mask_elaborat); title('T4: Elaborat');

%% Tasca 5: Gravar vídeo
se_erode = strel('disk', 1);
se_dilate = strel('disk', 4);

v = VideoWriter('resultat.avi'); 
v.FrameRate = 15;
open(v);

for i = 1:num_test
    idx_seq = idx_start + num_train + i - 1;
    img_seq = double(rgb2gray(imread(fullfile(input_dir, sprintf('in%06d.jpg', idx_seq)))));
    
    foreground = abs(img_seq - mu) > (alpha * sigma + beta);
    foreground_clean = imdilate(imerode(foreground, se_erode), se_dilate);
    
    writeVideo(v, double(foreground_clean)); 
end
close(v);

%% Tasca 6: Avaluació i Accuracy
acc_c1 = zeros(num_test, 1);
acc_c2 = zeros(num_test, 1);
acc_c3 = zeros(num_test, 1);

for i = 1:num_test
    idx_seq = idx_start + num_train + i - 1;
    
    img_seq = double(rgb2gray(imread(fullfile(input_dir, sprintf('in%06d.jpg', idx_seq)))));
    gt = imread(fullfile(gt_dir, sprintf('gt%06d.png', idx_seq)));
    
    diferencia = abs(img_seq - mu);
    
    % Ens quedem només amb fons (0) i vehicle (255) pur, descartem ombres/fronteres
    roi = (gt == 0) | (gt == 255);
    gt_binari = (gt == 255);
    
    % Model simple (T3)
    mask1 = diferencia > thr_simple;
    acc_c1(i) = sum(mask1(roi) == gt_binari(roi)) / sum(roi(:));
    
    % Model elaborat (T4 sense morfologia)
    mask2 = diferencia > (alpha * sigma + beta);
    acc_c2(i) = sum(mask2(roi) == gt_binari(roi)) / sum(roi(:));
    
    % Model final (+morfologia)
    mask3 = imdilate(imerode(mask2, se_erode), se_dilate);
    acc_c3(i) = sum(mask3(roi) == gt_binari(roi)) / sum(roi(:));
end

fprintf('\nAccuracy (Mitjana de les 150 imatges de test):\n');
fprintf('Cas 1 (T3 Simple):            %.4f\n', mean(acc_c1));
fprintf('Cas 2 (T4 Elaborat brut):     %.4f\n', mean(acc_c2));
fprintf('Cas 3 (T4 Elaborat + Filtres): %.4f\n', mean(acc_c3));
