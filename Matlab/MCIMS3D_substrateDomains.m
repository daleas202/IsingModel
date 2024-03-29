% Monte Carlo Ising Model
% Ashley Dale
% Calls the following matlab files: initializeLattice.m,
% equilibrateSpins_H.m

%%
tic
clear;

ROOT_DIR = 'C:\Users\daleas\OneDrive - Indiana University\LD06517_MCIMS_results';

bd = 3000.5;
k_b = 8.617333262*10^-5;%eV/K
weights = [1 0.7071 0.5 0];
%L = [302];
L = [300];
D = 11;

%substrateImg = 'C:\Users\daleas\Documents\GitHub\IsingModel\Matlab\210428_1trialRuns\210428a__502spins\frames\502spins_1.7437K_5img.png';
substrateImg = 'C:\Users\daleas\Documents\substrates\210427_1trialRunsflattenSpins.png';
substrateWeight = 1;

J_K = 20;%
T_K = 297;
big_delta_K = bd;%K
ln_g = 83.9/8.31;
G = 0;%K

pLS = 0; %percentage of interior spins locked in LS
pHS = 0; %percentage of interior spins locked in HS
boundCond = (0); %boundary condition
omega = 1;

bD_nom = num2str(big_delta_K);
J_nom = num2str(J_K);

J_ev = J_K*k_b; %coupling constant/exchange energy in eV
T_ev = T_K.*k_b;
bD_ev = big_delta_K*k_b;
k = J_ev./(k_b.*T_K); % dimensionless inverse temperature
H = 0; %external magnetic field

%% DIMENSIONLESS UNITS

big_delta = (k_b*big_delta_K)/J_ev;
T = (k_b.*T_K)./J_ev;
J = J_ev/J_ev;
G = (k_b*G)/J_ev;

T_inv = (J_ev.*T_K)./k_b;

%%
evo = 0; %number of MC steps to let the system burn in; this is discarded
dataPts = 10e2; %number of MC steps to evaluate the system
frameRate = 1e9+1; % provides a modulus to save snapshot of system
numTrials = 1; %number of times to repeat the experiment

% save intermediate results:
saveIntResults = false;

%Energy output variables
E = zeros(1, length(T_K));
Snn = zeros(1, length(T_K));

%Magnetism output variables
B = zeros(1, length(T_K));

%Spin fraction output variables
nHS = zeros(length(T_K), dataPts);
nHS_evo = zeros(length(T_K), evo);
%%
%APSslideColor = [34/255, 42/255, 53/255];
APSslideColor = [1 1 1];

set(0,'DefaultFigureColor',APSslideColor)

t = datetime('now');
t.Format = "yyMMdd";
dat_str0 = string(t);

if saveIntResults
    % save all trials in a single directory at highest level
    tryName = num2str(numTrials);
    trial_dir = strcat(dat_str0,'_',tryName,'trialRuns');
    mkdir(trial_dir)
else
    % no group directory required
    trial_dir = '..';
end
%%

%results folder for this particular data run

t = datetime('now');
t.Format = "yyMMddhhmm";
dat_str = string(t);
dir_name = strcat(trial_dir,'/',dat_str,'_',num2str(L(1)),'spins3D');
mkdir(dir_name)
mkdir(dir_name,'frames')
mkdir(dir_name,'png')
mkdir(dir_name,'fig')
mkdir(dir_name,'txt')


%% initialize 3D lattice
N = L(1);

substrate = imresize(imread(substrateImg), [N, N]);
substrate = 2.*double(substrate./255) - 1;
substrate = substrateWeight.*substrate;

[spinsOG, listLS] = initializeLattice3D_substrate(...
    N, D, boundCond, pLS, pHS, substrate);

% View initial lattice
%%{
figure
spinVis(spinsOG);
set(gca,'xticklabel',[])
set(gca,'yticklabel',[])
set(gca,'zticklabel',[])
set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'ztick',[])
set(gca, 'Color', APSslideColor)
pause(3)
close
%}

figure;
%%
spins = spinsOG;

for temp = 1:length(k)
    %let state reach equilibrium
    X = sprintf('Cooling %d x %d x %d spins to temp %f ....',...
        N, N, D, T_K(temp));
    disp(X)
    
    tic
    [spins, ~, nHS_evo(temp, :)] = equilibrateSpins_3D(...
        evo, spins, k(temp), T(temp), omega, weights, J, ...
        big_delta, ln_g, listLS, ...
        frameRate, dir_name, saveIntResults);
    
    
    %take data
    fprintf("Taking Data\n")
    [spins, E, nHS(temp, :)] = ...
        equilibrateSpins_3D(...
        dataPts, spins, k(temp), T(temp), omega, weights, J, ...
        big_delta, ln_g, listLS, ...
        frameRate, dir_name, 'false');
    
    close;
    %%
    
    %%{
    rootName = strcat(dat_str, num2str(N),...
        'spins_k_', num2str(T_K(temp)), 'K');
    if saveIntResults
        
        file_name = strcat(dir_name,'/txt/',rootName,'.txt');
        png_name = strcat(dir_name,'/png/',rootName, '.png');
        fig_name = strcat(dir_name,'/fig/',rootName, '.fig');
        %save spin matrix to text file
        writematrix(spins,file_name);
        
        %save final spin
        f = figure;
        spinVis(spins);
        title({strcat(num2str(T_K(temp)), 'K')},...
            'Interpreter', 'tex',...
            'Color', 'white');
        set(gca,'xticklabel',[])
        set(gca,'yticklabel',[])
        set(gca,'zticklabel',[])
        set(gca,'xtick',[])
        set(gca,'ytick',[])
        set(gca,'ztick',[])
        set(gca, 'Color', APSslideColor)
        set(gcf, 'Color', APSslideColor)
        set(gcf, 'InvertHardcopy', 'off')
        saveas(gcf, png_name);
        saveas(gcf, fig_name);
        close
    end
    %}
    toc
end
%%

save(strcat(dir_name,'/', rootName))

%% PLOTTING

legArr = makeLegend(L, D);
set(0,'DefaultTextInterpreter','none')

if numTrials > 1
    
    meanE = squeeze(mean(E));
    mean_nHS = squeeze(mean(nHS))';
    
    
    %%
    close all
    
    plt_title = 'High Spin Fraction vs Temperature';
    figure
    plot(T_inv, mean_nHS,'*-k')
    hold on
    title({plt_title}, 'Interpreter', 'tex')
    xlabel("Temperature T (K)")
    ylabel("n_H_S", 'Interpreter','tex')
    legend(legArr,'Location','southeast')
    axis([-inf inf 0 1.0])
    hold off
    saveas(gcf, strcat(trial_dir,'/',dat_str0,'_',...
        'delt',bD_nom,'_J',J_nom,'_nHSvsT','.png'))
    
    writematrix([T_inv' mean_nHS], strcat(trial_dir,'/',dat_str0,'_',...
        'delt',bD_nom,'_J',J_nom,'_nHSvsT','.txt'));
else
    nHSmean = mean(nHS, 2);
    
    plt_title = 'High Spin Fraction vs Temperature';
    
    %     figure
    %     plot(T_K', nHSmean, '.-c')
    %     hold on
    %     title({plt_title},'Interpreter', 'tex', 'Color', 'white')
    %     xlabel("Temperature T (K)")
    %     ylabel({'n_H_S'},'Interpreter','tex')
    %     %legend(legArr,'Location','southeast')
    %     axis([-inf inf 0 1.0])
    %     set(gca, 'Color', APSslideColor)
    %     %set(gca, 'XColor', [0, 0, 0])
    %     %set(gca, 'YColor', [0, 0, 0])
    %     grid on
    %     hold off
    %     set(gcf, 'InvertHardcopy', 'off')
    %
    %     imgHSvTemp = strcat(dir_name,'/',dat_str,'_',...
    %         'delt',bD_nom,'_J',J_nom,'_nHSvsT');
    %
    %     saveas(gcf, strcat(imgHSvTemp,'.png'))
    %     saveas(gcf, strcat(imgHSvTemp,'.fig'))
    %
    %     writematrix([T_K' nHSmean], strcat(imgHSvTemp,'.txt'));
    
    %%
    %Plot nHS vs steps
    plt_title = 'Spin High Fraction vs Time';
    figure
    hold on
    
    for idx = 1:length(T)
        plot(1:dataPts, nHS(idx, :), '.-c')
    end
    set(gca, 'Color', APSslideColor)
    %set(gca, 'XColor', [1, 1, 1])
    %set(gca, 'YColor', [1, 1, 1])
    grid on
    ylabel({'n_H_S'},'Interpreter','tex')
    xlabel("Time (MCIMS Step)")
    title({plt_title}, 'Color', 'white')
    set(gcf, 'InvertHardcopy', 'off')
    
    imgHSvTime = strcat(dir_name,'/',dat_str,'timeAvg_',...
        'delt',bD_nom,'_J',J_nom,'_nHSvsTime');
    
    saveas(gcf,strcat(imgHSvTime, '.png'));
    saveas(gcf, strcat(imgHSvTime, '.fig'));
    
    writematrix([(1:dataPts)' nHS(idx,:)'], strcat(imgHSvTime,'.txt'));
    
    %%
    % Plot nHS evolution
    %     plt_title = 'Spin High Fraction vs Time';
    %     figure
    %     hold on
    %     for idx = 1:length(T)
    %         plot(1:evo, nHS_evo(idx, :), '.-c')
    %     end
    %     set(gca, 'Color', APSslideColor)
    %     %set(gca, 'XColor', [1, 1, 1])
    %     %set(gca, 'YColor', [1, 1, 1])
    %     grid on
    %     ylabel({'n_H_S'},'Interpreter','tex')
    %     xlabel("Time (MCIMS Step)")
    %     title({plt_title}, 'Color', 'white')
    %     set(gcf, 'InvertHardcopy', 'off')
    %     saveas(gcf, strcat(dir_name,'/',dat_str,'timeEvo_',...
    %         'delt',bD_nom,'_J',J_nom,'_nHSvsT.png'))
    %     saveas(gcf, strcat(dir_name,'/',dat_str,'timeEvo_',...
    %         'delt',bD_nom,'_J',J_nom,'_nHSvsT.fig'))
    %
    %     writematrix([(1:dataPts)' nHS(idx,:)'], strcat(dir_name,'/',dat_str,'timeEvo_',...
    %         'delt',bD_nom,'_J',J_nom,'_nHSvsTime','.txt'));
    
end
%%
sliceSpins(spins)
sliceImgName = strcat(dir_name,'/',dat_str,'slices',...
    'delt',bD_nom,'_J',J_nom);
saveas(gcf, strcat(sliceImgName, '.png'));
%%
dataSetName = strcat(dir_name, '/', dat_str, '_DATA.mat');
save(dataSetName)

function legArr = makeLegend(L,D)
%returns a legend given an array of lattice sizes
legArr = cell(max(size(L)),1);
for idx = 1:max(size(L))
    legArr{idx} = strcat(num2str(L(idx)),'x',num2str(L(idx)),'x',num2str(D),' spins');
end
end

function sliceSpins(spins)

[M, N, P] = size(spins);

numRows = floor(sqrt(P));
numCols = ceil(P/numRows);

figure;
hold on

for idx = 1:P
    subplot(numRows, numCols, idx)
    imagesc(spins(:, :, idx))
    axis square
    xticklabels([])
    yticklabels([])
end

end