function show_bvecs(bvec_txt)
close all
bvecs = load(bvec_txt);
figure('position',[100 100 500 500]);
size(bvecs)
plot3(bvecs(1,:),bvecs(2,:),bvecs(3,:),'*r');
axis([-1 1 -1 1 -1 1]);
xlabel('x')
ylabel('y')
zlabel('z')
grid on
rotate3d