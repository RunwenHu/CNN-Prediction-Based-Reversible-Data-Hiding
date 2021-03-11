function complexity = calculate_complexity(img, i, j)
%º∆À„±≥æ∞∏¥‘”∂»
v1 = abs(img(i, j-1) - img(i-1, j));
v2 = abs(img(i-1, j) - img(i, j+1));
v3 = abs(img(i, j+1) - img(i+1, j));
v4 = abs(img(i+1, j) - img(i, j-1));
% v = [v1, v2, v3, v4];
% complexity = sum((v - vk).*(v - vk))/4;
complexity = (v1+v2+v3+v4)/4;
end