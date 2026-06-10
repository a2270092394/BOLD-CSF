% 询问使用者数据的文件夹位置
base_path = uigetdir('', '请选择数据文件夹');

% 询问使用者list.txt的位置
[list_file, list_path] = uigetfile('*.txt', '请选择list.txt文件');
list = textread(fullfile(list_path, list_file), '%s');

% 初始化存储信号的变量
all_average_csf_signals = [];
all_global_bold_signals = [];
all_ccfs = [];
all_derivative_ccfs = [];
all_neg_derivative_bolds = [];

% 弹出对话框让用户输入TR值
prompt = {'请输入TR（重复时间）（单位：秒）：'};
dlg_title = '输入TR';
num_lines = 1;
defaultans = {'2.0'};

answer = inputdlg(prompt, dlg_title, num_lines, defaultans);

% 将用户输入的TR值转换为数字
if ~isempty(answer)
    TR = str2double(answer{1});
else
    error('用户未输入TR值。');
end

% 显示用户输入的TR值
disp(['用户输入的TR值为：', num2str(TR), ' 秒']);


% 遍历每个被试
for i = 1:length(list)
    subject = list{i};
    subject_path = fullfile(base_path, subject);
    
    % 构建文件路径
    gfmri_filename = fullfile(subject_path, 'gfmri.nii');
    cfmri_filename = fullfile(subject_path, 'cfmri.nii');
    csf_mask_filename = fullfile(subject_path, 'CSF_mask.nii');
    gray_matter_mask_filename = fullfile(subject_path, 'individual_cortex.nii');
    
    % 加载fMRI数据和CSF掩膜
    if exist(gfmri_filename, 'file') ~= 2 || exist(cfmri_filename, 'file') ~= 2 || exist(csf_mask_filename, 'file') ~= 2 || exist(gray_matter_mask_filename, 'file') ~= 2
        warning('文件缺失: %s', subject);
        continue;
    end
    
    fmri_info = niftiinfo(gfmri_filename);
    fmri_img = niftiread(gfmri_filename);

    csf_mask_info = niftiinfo(csf_mask_filename);
    csf_mask = niftiread(csf_mask_filename);

    % 检查并重新采样CSF掩膜
    [x, y, z, t] = size(fmri_img);
    if ~isequal(size(csf_mask), [x, y, z])
        csf_mask = imresize3(csf_mask, [x, y, z], 'nearest');
    end

    % 提取并标准化CSF区域的时间序列信号
    csf_mask_reshaped = reshape(csf_mask, [], 1);
    csf_signals = zeros(sum(csf_mask_reshaped > 0), t);

    for time_point = 1:t
        current_fmri_data = fmri_img(:, :, :, time_point);
        current_fmri_data_reshaped = reshape(current_fmri_data, [], 1);
        csf_signals(:, time_point) = current_fmri_data_reshaped(csf_mask_reshaped > 0);
    end

    % 对每个体素进行Z分数标准化
    csf_signals_zscored = zscore(csf_signals, 0, 2);

    % 计算每个时间点的平均CSF信号
    average_csf_signal = nanmean(csf_signals_zscored, 1);

    % 提取全局BOLD信号
    gray_matter_mask_info = niftiinfo(gray_matter_mask_filename);
    gray_matter_mask = niftiread(gray_matter_mask_filename);

    if ~isequal(size(gray_matter_mask), [x, y, z])
        gray_matter_mask = imresize3(gray_matter_mask, [x, y, z], 'nearest');
    end

    gray_matter_mask_reshaped = reshape(gray_matter_mask, [], 1);
    gray_signals = zeros(sum(gray_matter_mask_reshaped > 0), t);

    for time_point = 1:t
        current_fmri_data = fmri_img(:, :, :, time_point);
        current_fmri_data_reshaped = reshape(current_fmri_data, [], 1);
        gray_signals(:, time_point) = current_fmri_data_reshaped(gray_matter_mask_reshaped > 0);
    end

    % 对每个体素进行Z分数标准化
    gray_signals_zscored = zscore(gray_signals, 0, 2);

    % 计算每个时间点的平均BOLD信号
    global_bold_signal = nanmean(gray_signals_zscored, 1);

    % 计算BOLD信号的负一阶导数
    neg_derivative_bold = -diff(global_bold_signal);
    all_neg_derivative_bolds = [all_neg_derivative_bolds; neg_derivative_bold];

    % 定义时间点数组
    time_points = (0:length(neg_derivative_bold)-1) * TR;

    % 可视化并保存负一阶导数信号
    figure;
    plot(time_points, neg_derivative_bold, '-o');
    xlabel('Time (seconds)');
    ylabel('Negative First-order Derivative of BOLD Signal');
    title(['Negative First-order Derivative of BOLD Signal - ', subject]);
    grid on;
    saveas(gcf, fullfile(subject_path, [subject, '_neg_derivative_bold.tif']), 'tiff');
    print(gcf, fullfile(subject_path, [subject, '_neg_derivative_bold.tif']), '-dtiff', '-r300');
    
    % 计算互相关函数
    average_csf_signal = average_csf_signal(1:end-1); % 去掉最后一个时间点
    fs = 1 / TR; % 采样频率 (Hz)
    time_lag_seconds = TR * 5; % 时间滞后范围 (秒)
    max_lag = time_lag_seconds * fs; % 最大滞后样本点数

    [ccf_derivative, lags] = xcorr(neg_derivative_bold, average_csf_signal, max_lag, 'coeff');

    % 转换滞后样本点数为时间滞后
    lags = lags * TR;

    % 限制滞后范围
    valid_range = (lags >= -time_lag_seconds) & (lags <= time_lag_seconds);
    ccf_derivative = ccf_derivative(valid_range);

    % 将数据添加到汇总变量中
    all_derivative_ccfs = [all_derivative_ccfs; ccf_derivative];

    % 可视化并保存互相关函数
    figure;
    plot(lags(valid_range), ccf_derivative, '-o');
    xlabel('Lag (seconds)');
    ylabel('Cross-correlation coefficient');
    title(['Cross-correlation Function - ', subject]);
    grid on;
    saveas(gcf, fullfile(subject_path, [subject, '_cross_correlation_derivative.tif']), 'tiff');
    print(gcf, fullfile(subject_path, [subject, '_cross_correlation_derivative.tif']), '-dtiff', '-r300');
end

% 保存所有被试的负一阶导数信号到Excel文件，每个被试一行
writematrix(all_neg_derivative_bolds, fullfile(base_path, 'all_neg_derivative_bolds.xlsx'), 'Sheet', 1, 'Range', 'A1');

% 保存所有被试的互相关函数到Excel文件，每个被试一行
writematrix(all_derivative_ccfs, fullfile(base_path, 'all_derivative_ccfs.xlsx'), 'Sheet', 1, 'Range', 'A1');
