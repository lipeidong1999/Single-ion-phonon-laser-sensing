%% ============================================================
% Fig. 2b: Phonon distribution fitting for all datasets (A1-A4, B1-B4)
% Method: Pn = Pn0 * exp(a*n + b*n^2) / Z
% Fit parameters: omega, a, b
% This script generates Rabi oscillation comparison plots for verification.
% The final phonon distribution figures are plotted via Python.
% ============================================================
clc; clear; close all;

%% ================== 1. Fully Automatic Path Configuration ==================
script_dir = fileparts(mfilename('fullpath'));
zip_file = fullfile(script_dir, 'Fig2b_Data.zip');

% Step 1: Automatically extract the zip file if it exists and hasn't been extracted
if exist(zip_file, 'file') && ~exist(fullfile(script_dir, 'Fig2b_Data'), 'dir')
    fprintf('Extracting Fig2b_Data.zip...\n');
    unzip(zip_file, script_dir);
end

% Step 2: Automatically search for the folder containing 'A1', 'A2', ... 'B4'
candidates = {
    fullfile(script_dir, 'Fig2b_Data', 'Raw_Data'), % Layout: Fig2b_Data/Raw_Data/A1
    fullfile(script_dir, 'Fig2b_Data'),             % Layout: Fig2b_Data/A1
    fullfile(script_dir, 'Raw_Data'),               % Layout: Raw_Data/A1
    script_dir                                      % Layout: A1 directly in current folder
};

base_dir = '';
for i = 1:length(candidates)
    if exist(fullfile(candidates{i}, 'A1'), 'dir')
        base_dir = candidates{i};
        break;
    end
end

if isempty(base_dir)
    error(['Could not locate the data folder containing A1-A4 and B1-B4. ' ...
           'Please ensure "Fig2b_Data.zip" is in the same folder as this script, ' ...
           'or that the unzipped folder contains the A1-B4 subfolders.']);
end

% Step 3: Automatically set save directory
save_dir = fullfile(script_dir, 'Analysis_Result');
if ~exist(save_dir, 'dir'); mkdir(save_dir); end

fprintf('Using Raw Data from: %s\n', base_dir);
fprintf('Results will be saved to: %s\n\n', save_dir);

%% ================== 2. Dataset Configuration ==================
datasets = {
    struct('name', 'A1', 'omega0', 2*pi*10.34,  'Pn0', [0.422198 0.403086 0.140578 0.029250 0.004335 0.000501 0.000048 0.000004 0 0 0 0 0 0 0 0 0 0 0 0 0]),
    struct('name', 'A2', 'omega0', 2*pi*10.605, 'Pn0', [0.122762 0.235420 0.255705 0.192667 0.111113 0.051980 0.020494 0.006997 0.002110 0.000571 0.000140 0.000032 0.000007 0.000001 0 0 0 0 0 0 0]),
    struct('name', 'A3', 'omega0', 2*pi*11,     'Pn0', [0.300443 0.373571 0.216890 0.080956 0.022252 0.004852 0.000879 0.000137 0.000019 0.000002 0 0 0 0 0 0 0 0 0 0 0]),
    struct('name', 'A4', 'omega0', 2*pi*11.81,  'Pn0', [0.021584 0.065459 0.123085 0.167692 0.179315 0.158039 0.118660 0.077731 0.045231 0.023710 0.011324 0.004973 0.002023 0.000768 0.000273 0.000092 0.000029 0.000009 0.000003 0.000001 0]),
    struct('name', 'B1', 'omega0', 2*pi*11.2,   'Pn0', [0.459065 0.464053 0.070846 0.005703 0.000319 0.000014 0.000001 0 0 0 0 0 0 0 0 0 0 0 0 0 0]),
    struct('name', 'B2', 'omega0', 2*pi*10.87,  'Pn0', [0.137042 0.290036 0.278777 0.172651 0.079551 0.029464 0.009202 0.002503 0.000607 0.000133 0.000027 0.000005 0.000001 0 0 0 0 0 0 0 0]),
    struct('name', 'B3', 'omega0', 2*pi*11.97,  'Pn0', [0.243860 0.392125 0.241281 0.091036 0.025031 0.005477 0.001005 0.000160 0.000023 0.000003 0 0 0 0 0 0 0 0 0 0 0]),
    struct('name', 'B4', 'omega0', 2*pi*11.96,  'Pn0', [0.032159 0.106148 0.181005 0.208832 0.183561 0.131403 0.079934 0.042547 0.020244 0.008750 0.003479 0.001285 0.000445 0.000145 0.000045 0.000013 0.000004 0.000001 0 0 0])
};

%% ================== 3. Global Parameters ==================
n_runs   = 6;
eta      = 0.114;
gamma    = 0.6501;
gamma_k  = 0.6635;
s        = 1;
scale_factor = 10;
Nmc      = 100;
options  = optimoptions('fmincon','Display','off','MaxFunctionEvaluations',2e4,'MaxIterations',2e3);

%% ================== 4. Loop over datasets ==================
for d = 1:length(datasets)
    dataset_name = datasets{d}.name;
    Pn0 = datasets{d}.Pn0;
    Pn0 = Pn0 / sum(Pn0);
    n_max = length(Pn0) - 1;
    n_list = 0:n_max;
    omega0 = datasets{d}.omega0;
    
    fprintf('\n===== Processing dataset: %s =====\n', dataset_name);
    
    % Read 6 BSB files
    Y = [];
    for k = 1:n_runs
        fname = fullfile(base_dir, dataset_name, num2str(k), 'bsb.txt');
        if ~exist(fname, 'file')
            error('File not found: %s. Please check your data structure.', fname);
        end
        data = load(fname);
        t{k} = data(:,1);
        y{k} = data(:,2);
        Y = [Y; y{k}'];
    end
    t_exp  = t{1};
    y_mean = mean(Y,1);
    y_err  = std(Y,0,1);
    y_err(y_err < 1e-4) = 1e-4;
    
    % Fit parameters
    a0 = 0; b0 = 0;
    x0 = [omega0, a0, b0];
    lb = [2*pi*5, -0.01, -0.005];
    ub = [2*pi*20, 0.01, 0.005];
    
    obj = @(x) obj_methodA(x, Pn0, n_list, t_exp, y_mean, y_err, n_max, s, eta, gamma, gamma_k);
    x_fit = fmincon(obj, x0, [], [], [], [], lb, ub, [], options);
    omega_fit = x_fit(1); a_fit = x_fit(2); b_fit = x_fit(3);
    
    Pn_fit = deform_Pn(Pn0, n_list, a_fit, b_fit);
    y_fit = compute_P_up_Pn(Pn_fit, t_exp, n_max, s, eta, omega_fit, gamma, gamma_k);
    
    fprintf('omega/2pi = %.4f kHz\n', omega_fit/2/pi);
    fprintf('a = %.4f, b = %.4f\n', a_fit, b_fit);
    
    % Residuals
    residuals = Y - y_fit;
    resid_std = std(residuals,0,1);
    
    % Monte Carlo error estimation
    Pn_mc = zeros(Nmc, n_max+1);
    omega_mc = zeros(Nmc,1); a_mc = zeros(Nmc,1); b_mc = zeros(Nmc,1); n_mean_mc = zeros(Nmc,1);
    for k = 1:Nmc
        y_mc_omega = y_mean + resid_std .* randn(size(y_mean));
        y_mc_ab    = y_mean + scale_factor * resid_std .* randn(size(y_mean));
        
        obj_mc_omega = @(x) obj_methodA([x a_fit b_fit], Pn0, n_list, t_exp, y_mc_omega, y_err, n_max, s, eta, gamma, gamma_k);
        omega_k = fmincon(obj_mc_omega, omega_fit, [], [], [], [], lb(1), ub(1), [], options);
        
        obj_mc_ab = @(x) obj_methodA([omega_k x], Pn0, n_list, t_exp, y_mc_ab, y_err, n_max, s, eta, gamma, gamma_k);
        ab_k = fmincon(obj_mc_ab, [a_fit b_fit], [], [], [], [], lb(2:3), ub(2:3), [], options);
        
        omega_mc(k) = omega_k; a_mc(k) = ab_k(1); b_mc(k) = ab_k(2);
        Pn_mc(k,:) = deform_Pn(Pn0, n_list, ab_k(1), ab_k(2));
        n_mean_mc(k) = sum(Pn_mc(k,:) .* n_list);
    end
    Pn_err = std(Pn_mc,0,1);
    omega_err = std(omega_mc)/2/pi;
    a_err = std(a_mc); b_err = std(b_mc);
    n_mean = sum(Pn_fit .* n_list);
    n_mean_err = std(n_mean_mc);
    
    fprintf('omega/2pi = %.4f ± %.4f kHz\n', omega_fit/2/pi, omega_err);
    fprintf('a = %.4f ± %.4f\n', a_fit, a_err);
    fprintf('b = %.4f ± %.4f\n', b_fit, b_err);
    fprintf('<n> = %.4f ± %.4f\n', n_mean, n_mean_err);
    
    % Save results to Excel
    excel_file = fullfile(save_dir, sprintf('Final_Analysis_Report_%s.xlsx', dataset_name));
    if exist(excel_file, 'file'); delete(excel_file); end
    
    y_sem = std(Y, 0, 1) / sqrt(n_runs);
    y_sem(y_sem < 1e-4) = 1e-4;
    n_mean_theory = sum(Pn0 .* n_list);
    true_n_mean_err = n_mean_err / scale_factor;
    true_Pn_err = Pn_err / scale_factor;
    
    T_Summary = table({'Omega/2pi (kHz)'; 'Mean_Phonon_n'; 'Deformation_a'; 'Deformation_b'}, ...
               [omega_fit/2/pi; n_mean; a_fit; b_fit], ...
               [omega_err; true_n_mean_err; a_err/scale_factor; b_err/scale_factor], ...
               [nan; n_mean_err; a_err; b_err], ...
               [nan; n_mean_theory; 0; 0], ...
               'VariableNames', {'Parameter', 'Exp_Value', 'Error_SEM_True', 'Error_Scaled_for_Plot', 'Theory_Value'});
    T_Pn = table(n_list', Pn_fit', true_Pn_err', Pn_err', Pn0', ...
        'VariableNames', {'n', 'Pn_Exp_Fit', 'Pn_Error_True', 'Pn_Error_Scaled_for_Plot', 'Pn_Theory'});
    
    writetable(T_Summary, excel_file, 'Sheet', 'Main_Results');
    writetable(T_Pn, excel_file, 'Sheet', 'Pn_Full_Data');
    fprintf('--> Excel saved: %s\n', excel_file);
    
    %% ================== 5. Plotting (Rabi Oscillation Only) ==================
    fSize = 10; axLW = 0.8;
    col_data = [0 0 0]; col_fit = [0.85 0.33 0.1];
    
    % --- BSB Rabi Oscillation Comparison ---
    fig1 = figure('Units', 'inches', 'Position', [2, 2, 3.375, 2.8], 'Color', 'w', 'Visible', 'off');
    ax1 = axes('Parent', fig1, 'FontSize', fSize, 'FontName', 'Times New Roman', ...
               'LineWidth', axLW, 'Box', 'on', 'TickLabelInterpreter', 'latex');
    hold(ax1, 'on');
    errorbar(t_exp, y_mean, y_sem, 'o', 'Color', col_data, 'MarkerSize', 3, ...
             'MarkerFaceColor', 'w', 'LineWidth', 0.7, 'CapSize', 0, 'DisplayName', 'Data (SEM)');
    plot(t_exp, y_fit, '-', 'Color', col_fit, 'LineWidth', 1.3, 'DisplayName', 'Fit');
    xlabel('$t$ (ms)', 'Interpreter', 'latex');
    ylabel('$P_{\uparrow}$', 'Interpreter', 'latex');
    legend('Location', 'northeast', 'Interpreter', 'latex', 'FontSize', 8, 'Box', 'off');
    set(ax1, 'XLim', [0, max(t_exp)*1.02], 'YLim', [0, 1]); 
    grid off;
    
    saveas(fig1, fullfile(save_dir, sprintf('Fig_Rabi_%s.fig', dataset_name)));
    exportgraphics(fig1, fullfile(save_dir, sprintf('Fig_Rabi_%s.pdf', dataset_name)), 'ContentType', 'vector');
    exportgraphics(fig1, fullfile(save_dir, sprintf('Fig_Rabi_%s.png', dataset_name)), 'Resolution', 600);
    close(fig1);
    
    fprintf('--> Rabi plot saved for %s\n', dataset_name);
end

fprintf('\nAll datasets processed successfully.\n');

%% ================== Local Functions ==================
function chi2 = obj_methodA(x, Pn0, n, t, y, yerr, n_max, s, eta, gamma, gamma_k)
    omega = x(1); a = x(2); b = x(3);
    Pn = deform_Pn(Pn0, n, a, b);
    yth = compute_P_up_Pn(Pn, t, n_max, s, eta, omega, gamma, gamma_k);
    chi2 = sum(((yth - y)./yerr).^2);
end

function Pn = deform_Pn(Pn0, n, a, b)
    w = exp(a*n + b*n.^2);
    Pn = Pn0 .* w;
    Pn = Pn / sum(Pn);
end

function P_up = compute_P_up_Pn(Pn, t, n_max, s, eta, omega, gamma, gamma_k)
    Nt = length(t);
    P_up = zeros(1,Nt);
    for it = 1:Nt
        sum_term = 0;
        for n = 0:n_max
            gamma_n = gamma*(n+1)^gamma_k;
            Omega_n = omega * sqrt(factorial(n)/factorial(n+s)) * Laguerre(n, s, eta^2);
            sum_term = sum_term + Pn(n+1)*exp(-gamma_n*t(it))*cos(Omega_n*t(it));
        end
        P_up(it) = 0.5*(1 - sum_term);
    end
end

function L = Laguerre(n,m,x)
    if n==0
        L = 1;
    elseif n==1
        L = -x + m + 1;
    else
        L0 = 1; L1 = -x + m + 1;
        for k = 1:n-1
            L = ((2*k+1+m-x).*L1-(k+m).*L0)/(k+1);
            L0 = L1; L1 = L;
        end
    end
end