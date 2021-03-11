
function [Tp, Tn] = calculate_tp_tn(predictedError, lengthMessage)

    %º∆À„Tp ∫ÕTn
    errorHistInfo = tabulate(predictedError(:));
    tempSum=0;
    k=1;
    while tempSum < lengthMessage
        [temp, indexInfo] = max(errorHistInfo(:, 2));
        tempSum = tempSum + temp;
        placeIndex(k) = errorHistInfo(indexInfo, 1); 
        errorHistInfo(indexInfo, :)= [];
        k = k + 1;
    end
    Tp = max(placeIndex);
    Tn = min(placeIndex); 
    
end