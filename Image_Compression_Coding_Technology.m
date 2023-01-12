close all
clear
clc

%Input Size: 256x256
data = imread("lena.png");
img = rgb2gray(data);
data = reshape(img, [1, 256*256]);

% Huffman Coding Simulation
[N, symbols] = hist(data,double(unique(data)));
p = N / (256*256);

[dict, avglen] = huffmandict(symbols,p);

lens = zeros(size(symbols));
for v = 1:length(symbols)
    len = length(cell2mat(dict(v,2,:)));
    lens(v) = len;
end

% bar(symbols, N);
Huffman_Coding_N = sum(lens.*N, "all");
Huffman_Coding_P = sum(lens.*p, "all");

Run_Length_Coding=[];
c=1;
for i=1:length(data)-1
    if(data(i)==data(i+1))
        c=c+1;
    else
        Run_Length_Coding=[Run_Length_Coding,c,data(i),];
    c=1;
    end
end
Run_Length_Coding=[Run_Length_Coding,c,data(length(data))];


Predictive_Coding = img(1:256, 2:256) - img(1:256, 1:255);

% histogram(Predictive_Coding)
% xlim([0 255])
