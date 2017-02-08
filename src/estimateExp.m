function [ A, B ] = estimateExp( y, x, y_0)
%assume y = A*exp(Bx) + y_0, estimate A, B

y_hat = log(y - y_0*0.99);

% y_hat = log(A) +  B * x
p = polyfit(x, y_hat, 1);

B = p(1);
A = exp(p(2));

end

