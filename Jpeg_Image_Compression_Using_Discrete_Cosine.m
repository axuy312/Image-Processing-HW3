clear
clc

imgRGB=imread('lena.png');
imgRGB = im2double(imgRGB).*255.0;

% An RGB to YCbCr color space conversion ( color specification )
colorT = [0.299 0.587 0.114; -0.169 0.334 0.500; 0.500 0.419 0.081];
bias = [0; 128; 128];
imgYCbCr = zeros(size(imgRGB));
for r = 1:size(imgRGB, 1)
    for c = 1:size(imgRGB, 2)
        vRGB = reshape(imgRGB(r, c, :), [3,1]);
        vYCbCr = colorT*vRGB+bias;
        imgYCbCr(r, c, :) = vYCbCr;
    end
end

% Original image is divided into blocks of 8 x 8. 
% The pixel values within each block range from[-128 to 127] but pixel values of a black and white image range from [0-255] so, each block is shifted from[0-255] to [-128 to 127].
imgYCbCr = imgYCbCr - 128.0;

% The DCT works from left to right, top to bottom thereby it is applied to each block.
imgDCT = zeros(size(imgYCbCr));
for r = 1:8:size(imgYCbCr, 1)
    for c = 1:8:size(imgYCbCr, 2)
        for k = 1:size(imgYCbCr, 3)
            vBlock = reshape(imgYCbCr(r:r+7, c:c+7, k), [8, 8]);
            imgDCT(r:r+7, c:c+7, k) = dct2(vBlock);
        end
    end
end

% Each block is compressed through quantization.
Qr = [16 11 10 16 24 40 51 61;12 12 14 19 26 58 60 55;14 13 16 24 40 57 69 56;14 17 22 29 51 87 80 62;18 22 37 56 68 109 103 77;24 35 55 64 81 104 113 92;49 64 78 87 103 121 120 101;72 92 95 98 112 100 103 99];
% Qr(:)=100;
Qc = [17 18 24 47 99 99 99 99;18 21 26 66 99 99 99 99;24 26 56 99 99 99 99 99;47 66 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99;99 99 99 99 99 99 99 99];
% Qc(:)=100;
imgQDCT = zeros(size(imgDCT));
for r = 1:8:size(imgDCT, 1)
    for c = 1:8:size(imgDCT, 2)
%       luminance
        k = 1;
        vBlock = reshape(imgDCT(r:r+7, c:c+7, k), [8, 8]);
        imgQDCT(r:r+7, c:c+7, k) = round(vBlock./Qr);
%       chrominance(Yb)
        k = 2;
        vBlock = reshape(imgDCT(r:r+7, c:c+7, k), [8, 8]);
        imgQDCT(r:r+7, c:c+7, k) = round(vBlock./Qc);
%       chrominance(Yr)
        k = 3;
        vBlock = reshape(imgDCT(r:r+7, c:c+7, k), [8, 8]);
        imgQDCT(r:r+7, c:c+7, k) = round(vBlock./Qc);
    end
end

% Huffman Coding Simulation
data = reshape((imgQDCT), [1, 256*256*3]);
[N, symbols] = hist(data,double(unique(data)));
p = N / (256*256*3);

[dict, avglen] = huffmandict(symbols,p);

lens = zeros(size(symbols));
for v = 1:length(symbols)
    len = length(cell2mat(dict(v,2,:)));
    lens(v) = len;
end

% Result of compression
code = huffmanenco(data,dict);

% bar(symbols, N);
Huffman_Coding_N = sum(lens.*N, "all");
Huffman_Coding_P = sum(lens.*p, "all");

%==========================================
% Reconstruction===========================
%==========================================

% Inverse of Huffman Coding
dataInverse = huffmandeco(code,dict);
dataInverse = reshape((dataInverse), [256, 256, 3]);

% Inverse of quantization.
imgQDCTInverse = zeros(size(dataInverse));
for r = 1:8:size(dataInverse, 1)
    for c = 1:8:size(dataInverse, 2)
%       luminance
        k = 1;
        vBlock = reshape(dataInverse(r:r+7, c:c+7, k), [8, 8]);
        imgQDCTInverse(r:r+7, c:c+7, k) = round(vBlock.*Qr);
%       chrominance(Yb)
        k = 2;
        vBlock = reshape(dataInverse(r:r+7, c:c+7, k), [8, 8]);
        imgQDCTInverse(r:r+7, c:c+7, k) = round(vBlock.*Qc);
%       chrominance(Yr)
        k = 3;
        vBlock = reshape(dataInverse(r:r+7, c:c+7, k), [8, 8]);
        imgQDCTInverse(r:r+7, c:c+7, k) = round(vBlock.*Qc);
    end
end


% Inverse of DCT works from left to right, top to bottom thereby it is applied to each block.
imgDCTInverse = zeros(size(imgQDCTInverse));
for r = 1:8:size(imgQDCTInverse, 1)
    for c = 1:8:size(imgQDCTInverse, 2)
        for k = 1:size(imgQDCTInverse, 3)
            vBlock = reshape(imgQDCTInverse(r:r+7, c:c+7, k), [8, 8]);
            imgDCTInverse(r:r+7, c:c+7, k) = idct2(vBlock);
        end
    end
end

% Original image is divided into blocks of 8 x 8. 
% Inverse of pixel values within each block range from[-128 to 127] but pixel values of a black and white image range from [0-255] so, each block is shifted from[0-255] to [-128 to 127].
imgYCbCrInverse = imgDCTInverse + 128.0;

% An YCbCr to RGB color space conversion ( color specification )
imgRGBInverse = zeros(size(imgYCbCrInverse));
for r = 1:size(imgYCbCrInverse, 1)
    for c = 1:size(imgYCbCrInverse, 2)
        vYCbCr = reshape(imgYCbCrInverse(r, c, :), [3,1]);
        vRGB = colorT^(-1)*(vYCbCr - bias);
        imgRGBInverse(r, c, :) = vRGB;
    end
end

% imwrite(uint8(imgRGBInverse),"R.png")
imshow(uint8(imgRGBInverse))

