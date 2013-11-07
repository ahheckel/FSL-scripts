function nets_plot(X);

figure;

X=normalise(X)/4;

for i=1:size(X,2)
  X(:,i)=X(:,i)+i;
end

plot(X);

grid on;

