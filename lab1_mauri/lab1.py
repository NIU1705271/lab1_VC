import os
import cv2
import numpy as np
from skimage import io, color, morphology
import matplotlib.pyplot as plt

# --- CONFIGURACIÓ DE PARÀMETRES ---
base_dir = 'highway'
input_dir = os.path.join(base_dir, 'input')
gt_dir = os.path.join(base_dir, 'groundtruth')

idx_start = 1051
num_train = 150
num_test = 150

# --- TASCA 1: Carregar dades ---
print("Carregant imatges de training...")
train_images_list = []

for i in range(num_train):
    img_idx = idx_start + i
    img_path = os.path.join(input_dir, f'in{img_idx:06d}.jpg')
    img = io.imread(img_path)
    img_gray = color.rgb2gray(img) * 255.0 # skimage escala de 0 a 1, passem a 0-255 com a MATLAB
    train_images_list.append(img_gray)

# Stackiem les imatges per tenir el tensor 3D: (files, columnes, temps)
train_images = np.stack(train_images_list, axis=2)

# --- TASCA 2: Model de fons ---
print("Calculant el model de fons...")
mu = np.mean(train_images, axis=2)
sigma = np.std(train_images, axis=2)

fig, axes = plt.subplots(1, 2, figsize=(10, 5))
fig.canvas.manager.set_window_title('Tasca 2: Model de fons')

axes[0].imshow(mu.astype(np.uint8), cmap='gray')
axes[0].set_title("Mitjana")
axes[0].axis('off')

axes[1].imshow(sigma, cmap='gray')
axes[1].set_title("Desviació Estàndard")
axes[1].axis('off')
plt.show()

# --- TASCA 3 i 4: Segmentació ---
print("Iniciant segmentació...")
alpha = 1.0
beta = 8
thr_simple = 50

# Triem una imatge de test com a exemple
img_idx_test = idx_start + num_test
img_test_path = os.path.join(input_dir, f'in{img_idx_test:06d}.jpg')
img_test = color.rgb2gray(io.imread(img_test_path)) * 255.0

mask_simple = np.abs(img_test - mu) > thr_simple
mask_elaborat = np.abs(img_test - mu) > (alpha * sigma + beta)

fig, axes = plt.subplots(1, 3, figsize=(15, 5))
fig.canvas.manager.set_window_title('Tasques 3 i 4')

axes[0].imshow(img_test, cmap='gray')
axes[0].set_title("Original")
axes[0].axis('off')

axes[1].imshow(mask_simple, cmap='gray')
axes[1].set_title("T3: Simple")
axes[1].axis('off')

axes[2].imshow(mask_elaborat, cmap='gray')
axes[2].set_title("T4: Elaborat")
axes[2].axis('off')
plt.show()

# --- TASCA 5: Gravar vídeo ---
print("Gravant vídeo...")
se_erode = morphology.disk(1)
se_dilate = morphology.disk(4)

# Setup del vídeo amb OpenCV
frame_height, frame_width = mu.shape
fourcc = cv2.VideoWriter_fourcc(*'XVID')
out = cv2.VideoWriter('resultat.avi', fourcc, 15.0, (frame_width, frame_height), isColor=False)

for i in range(num_test):
    idx_seq = idx_start + num_train + i
    img_seq_path = os.path.join(input_dir, f'in{idx_seq:06d}.jpg')
    img_seq = color.rgb2gray(io.imread(img_seq_path)) * 255.0
    
    foreground = np.abs(img_seq - mu) > (alpha * sigma + beta)
    
    # Morfologia
    foreground_clean = morphology.erosion(foreground, se_erode)
    foreground_clean = morphology.dilation(foreground_clean, se_dilate)
    
    # Gravem el frame
    frame = (foreground_clean * 255).astype(np.uint8)
    out.write(frame)

out.release()

# --- TASCA 6: Avaluació i Accuracy ---
print("Calculant Accuracy per 3 casos...")
acc_c1 = np.zeros(num_test)
acc_c2 = np.zeros(num_test)
acc_c3 = np.zeros(num_test)

for i in range(num_test):
    idx_seq = idx_start + num_train + i
    
    img_seq_path = os.path.join(input_dir, f'in{idx_seq:06d}.jpg')
    img_seq = color.rgb2gray(io.imread(img_seq_path)) * 255.0
    
    gt_path = os.path.join(gt_dir, f'gt{idx_seq:06d}.png')
    gt = io.imread(gt_path)
    
    # Si la imatge groundtruth es llegeix com a RGB o RGBA, la passem a gris/escala unicanal
    if len(gt.shape) > 2:
        gt = color.rgb2gray(gt[:,:,:3]) * 255.0
        gt = gt.astype(np.uint8)
        
    diferencia = np.abs(img_seq - mu)
    
    roi = (gt == 0) | (gt == 255)
    gt_binari = (gt == 255)
    
    # Cas 1: Simple
    mask1 = diferencia > thr_simple
    acc_c1[i] = np.sum(mask1[roi] == gt_binari[roi]) / np.sum(roi)
    
    # Cas 2: Elaborat
    mask2 = diferencia > (alpha * sigma + beta)
    acc_c2[i] = np.sum(mask2[roi] == gt_binari[roi]) / np.sum(roi)
    
    # Cas 3: Elaborat + Morfologia
    mask3 = morphology.dilation(morphology.erosion(mask2, se_erode), se_dilate)
    acc_c3[i] = np.sum(mask3[roi] == gt_binari[roi]) / np.sum(roi)

print("\nAccuracy (Mitjana de les 150 imatges de test):")
print(f"Cas 1 (T3 Simple):            {np.mean(acc_c1):.4f}")
print(f"Cas 2 (T4 Elaborat brut):     {np.mean(acc_c2):.4f}")
print(f"Cas 3 (T4 Elaborat + Filtres): {np.mean(acc_c3):.4f}")
