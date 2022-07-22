x = [  
];
y = zeros(528,522);
for n = 1:size(x,1)
    i = x(n,1)+1;
    j = x(n,2)+1;
    [i j ]
    y(i,j) = n;
end
pcolor(y); shading flat