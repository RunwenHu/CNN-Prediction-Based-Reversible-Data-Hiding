
function imgW = cnn_expansion(img, predictedImage, watermark, oddOrEvenNum)

%----------��չ����ˮӡ����-----------

img = double(img);
[M,N]=size(img);
mn=nextpow2(M*N);
imgW = img;
watermarkLength = length(watermark);%ˮӡ����

oddOrEvenPlace = zeros(M,N);
locationMap = zeros(M,N);
for i=2:M-1
    for j=2:N-1
        if mod((i+j),2)==oddOrEvenNum  %oddOrEvenNumΪ��1����ʾ������Ƕ�룬��0����ʾ��ż��Ƕ��
            oddOrEvenPlace(i,j)=1; %���������������ż��λǶ��ˮӡ���á�1�������
        end
    end
end
inserablePlace = find((oddOrEvenPlace==1));%��Ƕ��λ��
minimumLsbLength = watermarkLength+4*(mn);%Ԥ���趨Ҫ��LSB�㷨�滻����Ϣ����
currentLength = minimumLsbLength;%Ϊ�������ѭ�������嵱ǰ���ȣ���ʼλ�úͽ���λ��
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
            %������Ƕ���λ�ñ�1
            locationMap(i,j)=1; 
        end            
    end
    %����location map
    number1 = sum(sum(locationMap));
    number0 = M*N - number1;
    if number1==0
        compressedLocationMapBitlist = 0;
        number0 = 0;
    else
        compressedLocationMapBitlist = arithenco(locationMap(:)+1,[number0,number1]);
    end
    if currentLength - minimumLsbLength < length(compressedLocationMapBitlist)+4*mn
        currentLength = currentLength + 1000; %��ǰ���ȵ�����ÿ�ΰ�1000����
        startPlace = endPlace + 1;
        endPlace=currentLength;
    else
       break;
    end
end

%����ȡͼ���LSB��Ϣ
extractedLsbBitlist = [];
for k=length(inserablePlace):-1:length(inserablePlace)-(length(compressedLocationMapBitlist)+4*mn)+1
    extractedLsbBitlist(length(inserablePlace)-k+1) = bitget(imgW(inserablePlace(k)),1);
end

lengthCompressedLocationMapBitlist = num2bitlist(length(compressedLocationMapBitlist), mn);
%�Գ���+��������ʽ��ɴ�Ƕ��LocationMap
wholeCompressedLocationMapBitlist = [lengthCompressedLocationMapBitlist, compressedLocationMapBitlist'];


%�����Ƕ���
messageToEmbed = [extractedLsbBitlist,watermark];
messageToEmbedLength = num2bitlist(length(messageToEmbed),mn);


number1Bitlist = num2bitlist(number1, mn);
number0Bitlist = num2bitlist(number0, mn);

%Ҫ����lsb�滻�ı�������Ϣ
lsbToReplaceBitlist = [wholeCompressedLocationMapBitlist,...
messageToEmbedLength, number1Bitlist, number0Bitlist];


for k=length(inserablePlace):-1:length(inserablePlace)-length(lsbToReplaceBitlist)+1
    imgW(inserablePlace(k)) = imgW(inserablePlace(k)) ...
        - bitget(imgW(inserablePlace(k)),1)...
        + lsbToReplaceBitlist(length(inserablePlace)-k+1); 
end

%�滻lsb�����ˮӡ��ϢǶ��
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
