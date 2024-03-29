function [spins, E, nHS] = equilibrateSpins_periodic(...
    time, spins, T, weights, J, big_delta, ln_g, listLS, ...
    frameRate, dir_name, saveIntResults)
%{
%equilabrateSpins_H.m
%Ashley Dale

%Cools a matrix of spins to a given temperature, and at various times saves
%an image of the spin matrix to a file

%time: an integer that determines how long the system cools
%N: the square root of the number of spins
%k: 1/temperature
%mu: atomic magnetic moment
%H: external magnetic field
%J: spin exchange coupling constant
%ln_g: log of ratio of degeneracy HS to degeneracy LS
%G:
%listLS:
    
%frameRate: determines how frequently intermediate spin matrices are saved
%to an image
%spins_last: previous spin value
%dir_name: where to save results
%saveIntResults: boolean to control writing of frame samples

    %}
    f = waitbar(0,'1','Name','equilibrateSpins_H',...
        'CreateCancelBtn','setappdata(gcbf,''canceling'',Annealing)');
    
    setappdata(f, 'canceling', 0);
    
    set(0,'DefaultTextInterpreter','none');
    
    %k_b = 8.617333262*10^-5;%eV/K

    %B = zeros(time, 1);
    nHS = zeros(time, 1);
    [N, M] = size(spins);
    
    %% some optimization
    longRange = (big_delta/2 - T*ln_g/2);
    periodic = true;
    
    for idx = 1:time% how many times to let the system evolve
        
        if getappdata(f, 'canceling')
            break
        end
        
        waitbar(idx/time, f)
        
        for row = 1:N
            for col = 1:M
                i = row;
                j = col;
                tmp1 = find(listLS(:, 1) == row & listLS(:, 2) == col);

                if  ~ isempty(tmp1)
                    continue
                else

                    spinsLast = spins;

                    delta_sig = -1*spins(i,j) - spins(i,j);

                    %pick spin and flip right away
                    spins(i, j) = -1*spins(i,j);

                    sum_nn = sumNNNN(spins, i, j, weights, periodic);


                    %then do change in energy with correct sign
                    %dE = 2*spins(i,j) * (J*sum_nn + H*mu);
                    dE = delta_sig*(-1*J*sum_nn + (big_delta/2 - T*ln_g/2));
                    %dE = delta_sig*(-1*J*sum_nn);
                    
                    p = exp(-1*dE/T);
                    r = rand;

                    if dE < 0 || p >= r
                        continue
                    else
                        spins(i,j) = -1*spins(i,j);
                    end                   
                end
            end
        end
        
        %%
        %Snn = nearestN(spins);
        %sum_Si = sum(spins(2:N-1, 2:N-1), 'all');
        
        %E(idx, 1) = -J*Snn;
        %B(idx, 1) = mu*sum_Si;
        nHS(idx, 1) = n_HSfrac(spins);
        
        %{
    
    if mod(idx, frameRate) == 0
        pltTitle = strcat(num2str(N),'spins','_',num2str(T),'K_', num2str(idx));
        imagesc(spins)
        title(pltTitle)
        colorbar
        axis square;
        pause(0.05);
        if saveIntResults
            frame_name = strcat(dir_name,'\frames\',pltTitle,".png");
            saveas(gcf, frame_name)
        end
    end
    
        %}
        
    end
    delete(f)
    E = 0;
    %E = mean(E);
    %B = (mean(B)./(N*N));
    %nHS = mean(nHS);
    
end