
function imgW = cnn_histogram_shifting(img, predictedImage, watermark, oddOrEvenNum)

%----------直方图平移可逆水印方法-----------

img = double(img);
[M,N]=size(img);
mn=nextpow2(M*N);

imgW = img;
watermarkLength = length(watermark);

oddOrEvenPlace = zeros(M,N);
locationMap = zeros(M,N);
predictedError = zeros(M,N);%计算预测误差
complexity = zeros(M,N);

for i=2:M-1
    for j=2:N-1
        if mod((i+j),2)==oddOrEvenNum %oddOrEvenNum为“1”表示在奇数嵌入，“0”表示在偶数嵌入
            oddOrEvenPlace(i,j)=1;
            complexity(i, j)=calculate_complexity(imgW, i, j);%计算背景复杂度
        end
    end
end

inserablePlace = find((oddOrEvenPlace==1));
[~, indexComplexity] = sort(complexity(inserablePlace));%可嵌入位置
minimumLsbLength = watermarkLength+6*(mn);%预先设定要用LSB算法替换的信息长度
currentLength = minimumLsbLength; %为方便后续循环，定义当前长度，开始位置和结束位置
startPlace=1;
endPlace=currentLength; 
while(1)
    for k=startPlace:endPlace
        i = mod(inserablePlace(indexComplexity(k)),M);
        j = ceil(inserablePlace(indexComplexity(k))/M);
        x = imgW(i,j);
        xPredict = predictedImage(i,j);
        value = 2*x - xPredict;
        predictedError(i, j) = x - xPredict; %计算预测误差
        if (value>254)||(value<0)
            %不可以嵌入的位置标1
            locationMap(i,j)=1; 
        end            
    end
    %计算location map,number1和number0用来进行算数编码
    number1 = sum(sum(locationMap));
    number0 = M*N - number1;
    if number1==0
        compressedLocationMapBitlist = 0;
        number0 = 0;
    else
        compressedLocationMapBitlist = arithenco(locationMap(:)+1,[number0,number1]);
    end
    if currentLength - minimumLsbLength < length(compressedLocationMapBitlist)+6*mn
        currentLength = currentLength + 1000; %当前长度递增，每次按1000递增
        startPlace = endPlace + 1;
        endPlace=currentLength;
    else
       break;
    end
end
%在背景复杂度大的位置进行lsb替换，先提取最低有效位
extractedLsbBitlist = [];
for k=length(indexComplexity):-1:length(indexComplexity)-(length(compressedLocationMapBitlist)+6*mn)+1
    extractedLsbBitlist(length(indexComplexity)-k+1) = bitget(imgW(inserablePlace(indexComplexity(k))),1); %lsb_replace_bitlist为对应长度的lsb位
end
%以长度+比特流形式组成待嵌入LocationMap
lengthCompressedLocationMapBitlist = num2bitlist(length(compressedLocationMapBitlist), mn);
wholeCompressedLocationMapBitlist = [lengthCompressedLocationMapBitlist, compressedLocationMapBitlist'];

%待用直方图平移嵌入的信息
messageToEmbed = [extractedLsbBitlist,watermark];
messageToEmbedLength = num2bitlist(length(messageToEmbed),mn);

%计算Tp和Tn，方便嵌入
[Tp, Tn] = calculate_tp_tn(predictedError(inserablePlace(indexComplexity(1:endPlace))), length(messageToEmbed));

TpBitlist = num2bitlist(Tp, mn);
TnBitlist = num2bitlist(abs(Tn), mn);

number1Bitlist = num2bitlist(number1, mn);
number0Bitlist = num2bitlist(number0, mn);

%要进行LSB替换的比特流信息，6*mn
lsbToReplaceBitlist = [wholeCompressedLocationMapBitlist,...
messageToEmbedLength, TpBitlist, TnBitlist, number1Bitlist, number0Bitlist];

%进行LSB替换
for k=length(indexComplexity):-1:length(indexComplexity)-length(lsbToReplaceBitlist)+1
    imgW(inserablePlace(indexComplexity(k))) = imgW(inserablePlace(indexComplexity(k))) ...
        - bitget(imgW(inserablePlace(indexComplexity(k))),1)...
        + lsbToReplaceBitlist(length(indexComplexity)-k+1); 
end

%替换LSB后进行水印信息嵌入
indexMessage = 1;
for k=1:length(indexComplexity)
    i = mod(inserablePlace(indexComplexity(k)),M);
    j = ceil(inserablePlace(indexComplexity(k))/M);
    if locationMap(i,j)==0
        x = imgW(i,j);
        xPredict = predictedImage(i,j);
        dij= x - xPredict;
        if dij > Tp
            Dij = dij + Tp + 1;
            imgW(inserablePlace(indexComplexity(k)))=Dij + xPredict;
        elseif dij < Tn
            Dij = dij + Tn;
            imgW(inserablePlace(indexComplexity(k)))=Dij + xPredict;
        else
            if messageToEmbed(indexMessage)==1
                Dij = 2*dij + 1;
            else
                Dij = 2*dij + 0;
            end
            imgW(inserablePlace(indexComplexity(k)))=Dij + xPredict;
            indexMessage = indexMessage + 1;
            if indexMessage > length(messageToEmbed)
                break;
            end
        end
    end
end


end