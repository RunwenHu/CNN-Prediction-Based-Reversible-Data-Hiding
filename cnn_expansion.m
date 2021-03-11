
function imgW = cnn_expansion(img, predictedImage, watermark, oddOrEvenNum)

%----------扩展可逆水印方法-----------

img = double(img);
[M,N]=size(img);
mn=nextpow2(M*N);
imgW = img;
watermarkLength = length(watermark);%水印长度

oddOrEvenPlace = zeros(M,N);
locationMap = zeros(M,N);
for i=2:M-1
    for j=2:N-1
        if mod((i+j),2)==oddOrEvenNum  %oddOrEvenNum为“1”表示在奇数嵌入，“0”表示在偶数嵌入
            oddOrEvenPlace(i,j)=1; %标记是在奇数还是偶数位嵌入水印，用“1”来标记
        end
    end
end
inserablePlace = find((oddOrEvenPlace==1));%可嵌入位置
minimumLsbLength = watermarkLength+4*(mn);%预先设定要用LSB算法替换的信息长度
currentLength = minimumLsbLength;%为方便后续循环，定义当前长度，开始位置和结束位置
startPlace=1;
endPlace=currentLength; 
while(1)
    for k=startPlace:endPlace
        i = mod(inserablePlace(k),M);
        j = ceil(inserablePlace(k)/M);
        x = imgW(i,j);
        xPredict = predictedImage(i,j);
        value = 2*x - xPredict;
        if (value>254)||(value<0)
            %不可以嵌入的位置标1
            locationMap(i,j)=1; 
        end            
    end
    %计算location map
    number1 = sum(sum(locationMap));
    number0 = M*N - number1;
    if number1==0
        compressedLocationMapBitlist = 0;
        number0 = 0;
    else
        compressedLocationMapBitlist = arithenco(locationMap(:)+1,[number0,number1]);
    end
    if currentLength - minimumLsbLength < length(compressedLocationMapBitlist)+4*mn
        currentLength = currentLength + 1000; %当前长度递增，每次按1000递增
        startPlace = endPlace + 1;
        endPlace=currentLength;
    else
       break;
    end
end

%先提取图像的LSB信息
extractedLsbBitlist = [];
for k=length(inserablePlace):-1:length(inserablePlace)-(length(compressedLocationMapBitlist)+4*mn)+1
    extractedLsbBitlist(length(inserablePlace)-k+1) = bitget(imgW(inserablePlace(k)),1);
end

lengthCompressedLocationMapBitlist = num2bitlist(length(compressedLocationMapBitlist), mn);
%以长度+比特流形式组成待嵌入LocationMap
wholeCompressedLocationMapBitlist = [lengthCompressedLocationMapBitlist, compressedLocationMapBitlist'];


%计算待嵌入的
messageToEmbed = [extractedLsbBitlist,watermark];
messageToEmbedLength = num2bitlist(length(messageToEmbed),mn);


number1Bitlist = num2bitlist(number1, mn);
number0Bitlist = num2bitlist(number0, mn);

%要进行lsb替换的比特流信息
lsbToReplaceBitlist = [wholeCompressedLocationMapBitlist,...
messageToEmbedLength, number1Bitlist, number0Bitlist];


for k=length(inserablePlace):-1:length(inserablePlace)-length(lsbToReplaceBitlist)+1
    imgW(inserablePlace(k)) = imgW(inserablePlace(k)) ...
        - bitget(imgW(inserablePlace(k)),1)...
        + lsbToReplaceBitlist(length(inserablePlace)-k+1); 
end

%替换lsb后进行水印信息嵌入
indexMessage = 1;
for k=1:length(inserablePlace)
    i = mod(inserablePlace(k),M);
    j = ceil(inserablePlace(k)/M);
    if locationMap(i,j)==0
        x = imgW(i,j);
        xPredict = predictedImage(i,j);
        dij= x - xPredict;
        if messageToEmbed(indexMessage)==1
            Dij = 2*dij + 1;
        else
            Dij = 2*dij + 0;
        end
        imgW(inserablePlace(k))=Dij + xPredict;
        indexMessage = indexMessage + 1;
        if indexMessage > length(messageToEmbed)
            break;
        end
    end
end

end
