
function imgW = cnn_histogram_shifting(img, predictedImage, watermark, oddOrEvenNum)

%----------ֱ��ͼƽ�ƿ���ˮӡ����-----------

img = double(img);
[M,N]=size(img);
mn=nextpow2(M*N);

imgW = img;
watermarkLength = length(watermark);

oddOrEvenPlace = zeros(M,N);
locationMap = zeros(M,N);
predictedError = zeros(M,N);%����Ԥ�����
complexity = zeros(M,N);

for i=2:M-1
    for j=2:N-1
        if mod((i+j),2)==oddOrEvenNum %oddOrEvenNumΪ��1����ʾ������Ƕ�룬��0����ʾ��ż��Ƕ��
            oddOrEvenPlace(i,j)=1;
            complexity(i, j)=calculate_complexity(imgW, i, j);%���㱳�����Ӷ�
        end
    end
end

inserablePlace = find((oddOrEvenPlace==1));
[~, indexComplexity] = sort(complexity(inserablePlace));%��Ƕ��λ��
minimumLsbLength = watermarkLength+6*(mn);%Ԥ���趨Ҫ��LSB�㷨�滻����Ϣ����
currentLength = minimumLsbLength; %Ϊ�������ѭ�������嵱ǰ���ȣ���ʼλ�úͽ���λ��
startPlace=1;
endPlace=currentLength; 
while(1)
    for k=startPlace:endPlace
        i = mod(inserablePlace(indexComplexity(k)),M);
        j = ceil(inserablePlace(indexComplexity(k))/M);
        x = imgW(i,j);
        xPredict = predictedImage(i,j);
        value = 2*x - xPredict;
        predictedError(i, j) = x - xPredict; %����Ԥ�����
        if (value>254)||(value<0)
            %������Ƕ���λ�ñ�1
            locationMap(i,j)=1; 
        end            
    end
    %����location map,number1��number0����������������
    number1 = sum(sum(locationMap));
    number0 = M*N - number1;
    if number1==0
        compressedLocationMapBitlist = 0;
        number0 = 0;
    else
        compressedLocationMapBitlist = arithenco(locationMap(:)+1,[number0,number1]);
    end
    if currentLength - minimumLsbLength < length(compressedLocationMapBitlist)+6*mn
        currentLength = currentLength + 1000; %��ǰ���ȵ�����ÿ�ΰ�1000����
        startPlace = endPlace + 1;
        endPlace=currentLength;
    else
       break;
    end
end
%�ڱ������Ӷȴ��λ�ý���lsb�滻������ȡ�����Чλ
extractedLsbBitlist = [];
for k=length(indexComplexity):-1:length(indexComplexity)-(length(compressedLocationMapBitlist)+6*mn)+1
    extractedLsbBitlist(length(indexComplexity)-k+1) = bitget(imgW(inserablePlace(indexComplexity(k))),1); %lsb_replace_bitlistΪ��Ӧ���ȵ�lsbλ
end
%�Գ���+��������ʽ��ɴ�Ƕ��LocationMap
lengthCompressedLocationMapBitlist = num2bitlist(length(compressedLocationMapBitlist), mn);
wholeCompressedLocationMapBitlist = [lengthCompressedLocationMapBitlist, compressedLocationMapBitlist'];

%����ֱ��ͼƽ��Ƕ�����Ϣ
messageToEmbed = [extractedLsbBitlist,watermark];
messageToEmbedLength = num2bitlist(length(messageToEmbed),mn);

%����Tp��Tn������Ƕ��
[Tp, Tn] = calculate_tp_tn(predictedError(inserablePlace(indexComplexity(1:endPlace))), length(messageToEmbed));

TpBitlist = num2bitlist(Tp, mn);
TnBitlist = num2bitlist(abs(Tn), mn);

number1Bitlist = num2bitlist(number1, mn);
number0Bitlist = num2bitlist(number0, mn);

%Ҫ����LSB�滻�ı�������Ϣ��6*mn
lsbToReplaceBitlist = [wholeCompressedLocationMapBitlist,...
messageToEmbedLength, TpBitlist, TnBitlist, number1Bitlist, number0Bitlist];

%����LSB�滻
for k=length(indexComplexity):-1:length(indexComplexity)-length(lsbToReplaceBitlist)+1
    imgW(inserablePlace(indexComplexity(k))) = imgW(inserablePlace(indexComplexity(k))) ...
        - bitget(imgW(inserablePlace(indexComplexity(k))),1)...
        + lsbToReplaceBitlist(length(indexComplexity)-k+1); 
end

%�滻LSB�����ˮӡ��ϢǶ��
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