function [doubleBitlist] = num2bitlist(decNumber, bitNum)
%十进制转比特流
charBitlist = dec2bin(decNumber, bitNum);
[row ,column] = size(charBitlist);
doubleBitlist = zeros(1, row*column);
k=1;
for i=1:row
    for j=1:column
        doubleBitlist(k) = str2double(charBitlist(i,j));
        k = k+1;
    end
end
end