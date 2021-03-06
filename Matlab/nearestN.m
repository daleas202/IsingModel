%nearestN.m
%Ashley Dale
%Sums over all nearest neighbors

function Snn = nearestN(spins)
Snn = 0;
for i = 2:length(spins) - 1
    for j = 2:length(spins) - 1
        Snn = Snn + spins(i,j)*(spins(i-1,j) + spins(i+1,j) +...
            spins(i,j-1) + spins(i,j+1));
    end
end
%because we visit each spin 4 times, need to divide total interaction by 4
Snn = 0.25*Snn;
end