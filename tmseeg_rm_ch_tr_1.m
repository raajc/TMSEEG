% Author: Matthew Frehlich, Ye Mei, Luis Garcia Dominguez,Faranak Farzan
% 2016

% tmseeg_rm_ch_tr_1() - displays epoched TMSEEG data, allowing
% user adjustment of TMS Pulse removal with sliders denoting removal times.
%  Supports the single pulse and double pulse paradigms.
% 
% inputs:   A  - parent GUI structure (renamed from S to avoid conflict
% with S structure of tmseeg_rm_ch_tr_1
%           step_num - step of tmseeg_rm_ch_tr_1 in workflow

% Display window interface:
%       "Select Attribute" [popupmenu] Select option of ATTRIBUTE to
%       display in the main trial and channel removal windows.  Trials are
%       displayed as a feature extract based on ATTRIBUTE
%       "Plot Trials" [Button] calls the pb_tr_call() function,
%       displaying a scatter plot of the trals as their calculated
%       ATTRIBUTE value.
%       "Plot Channels" [Button] calls pb_ch_call(), displaying the
%       trials ATTRIBUTE extract on a channelwise basis
%       "EEGplot" [Button] calls eegplot() function from EEGPlot
%       software, allowing user to scroll through data displayed on a trial
%       by trial basis
%       "Clear Subject" [Button] - clears the current deletion matrix
%       "The Deleting Matrix" [Button] - Displays the current trials and
%       channels selected for deletion as an image
%       "Remove Bad Trials and Channels" [Button] - removes data as
%       specified by the deletion matrix

% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.

function  tmseeg_rm_ch_tr_1(A, step_num)
clc
global basepath basefile dotcolor linecolor backcolor existcolor VARS
linecolor = [1 0 0];
dotcolor  = linecolor;


% Main Figure
S.fh = figure('menubar','none',...
              'Toolbar','none',...
              'Units','normalized',...
              'name','tmseeg_remove_channel_trials',...
              'numbertitle','off',...
              'resize','off',...
              'color',backcolor,...
              'Position',[0.1 0.1 0.4 0.8],...
              'DockControls','off');


% ---------------------------GUI Buttons-----------------------------------
S.ls_var =  uicontrol('style','popupmenu',...
                'units','normalized',...
                'position',[.5 0.9 0.4 0.05],...
                'fontsize',12,...
                'value', 3,...
                'tag','vv',...
                'string',{'minmax w/ TMS Residual','minmax wo/ TMS Residual','High Freq'});
S.ls_notation = uicontrol('style','text',...
                'units','normalized',...
                'String','Select attribute for display:',...
                'position',[0.01 0.91 .44 0.04],...
                'fontsize',14,...
                'tag','vv_txt');
S.pb_tr = uicontrol('style','push',...
                'units','normalized',...
                'position',[0 0.7 1 0.1],...
                'fontsize',12,...
                'string','Plot Trials',...
                'callback',{@pb_tr_call,S});
S.pb_ch = uicontrol('style','push',...
                'units','normalized',...
                'position',[0 0.6 1 0.1],...
                'fontsize',12,...
                'string','Plot Channels',...
                'callback',{@pb_ch_call,S});
S.pb_eeg = uicontrol('style','push',...
                'units','normalized',...
                'position',[0 0.5 1 0.1],...
                'fontsize',12,...
                'string','EEGplot',...
                'callback',{@pb_eeg_call,S});
S.pb_clear = uicontrol('style','push',...
                'units','normalized',...
                'position',[0 0.4 1 0.1],...
                'fontsize',12,...
                'string','Clear Subject',...
                'callback',{@pb_clear_call,S});
S.pb_del_matrix = uicontrol('style','push',...
                'units','normalized',...
                'position',[0 0.3 1 0.1],...
                'fontsize',12,...
                'string','The Deleting Matrix',...
                'callback',{@pb_del_matrix_call,S});
S.pb_del = uicontrol('style','push',...
                'units','normalized',...
                'position',[0 0.2 1 0.1],...
                'fontsize',12,...
                'string','Remove Bad Trials and Channels',...
                'callback',{@pb_del_tr_ch_call,S,A});


%------------------------Load Channel and EEG Data-------------------------
S.step_num = step_num;

[file, EEG]           = tmseeg_load_step(S.step_num);
[~,name,~]          = fileparts(file.name); 
S.name              = name;

if ~exist(fullfile(basepath,[name '_' num2str(S.step_num) '_toDelete.mat']))
    S.toDelete = [];
else
    load(fullfile(basepath,[name '_' num2str(S.step_num) '_toDelete.mat']));
    S.toDelete = toDelete;
end

%Set bad channel/trial num based of pct and loaded data
VARS.NUM_BAD_CHANS  = ceil(EEG.nbchan*VARS.PCT_BAD_CHANS/100);
VARS.NUM_BAD_TRIALS = ceil(EEG.trials*VARS.PCT_BAD_TRIALS/100);



% Update GUI
guidata(S.fh,S);


end

%% Callback Functions

% Plot Trial Call
function [] = pb_tr_call(varargin)
%Load the EEG data from previous step, extract selected ATTRIBUTE using the
%Get_SM() function.  Displays Trials based on their ATTRIBUTE value.

global points dotcolor basepath backcolor

%Data Load
S       = varargin{3};
S       = guidata(S.fh);
S.EEG   = pop_loadset('filename',fullfile(basepath,[S.name '.set']));
S.M     = Get_SM(S.EEG);
S.ch    = [];
S.trial = [];
guidata(S.fh,S);

%Figure Setup
S.ft = figure('position',[40 80 800 500],'color', backcolor);
N = size(S.M,2);

%Scatter Plot
PlotScatter16(S);
points   = flipud(findobj(get(gca,'Children'),'type','scatter'));
set(gca,'NextPlot','add');
if ~isempty(S.toDelete)
    Del   = S.toDelete;
    Del   = Del(ismember(Del(:,2),0),:);
    set(points(Del(:,1)),'CData',dotcolor)   
end

%Set display
set(points, 'HitTest','on','ButtonDownFcn', {@button_down_points,S})
title('Trials represented by selected attribute')
xlabel('Trial Number')
attr = get(findobj('tag','vv'),'value');
lst  = get(findobj('tag','vv'),'string');
ylabel(lst(attr))
guidata(S.fh,S);
end

%Plot Channels Call
function [] = pb_ch_call(varargin)
%Load the EEG data from previous step, extract selected ATTRIBUTE using the
%Get_SM() function.  Creates a scatter plot for each channel and plot the
%Trials within that channel based on their ATTRIBUTE value.

global dotcolor basepath backcolor VARS

%Data Load and initialization
S       = varargin{3};
S       = guidata(S.fh);
S.EEG   = pop_loadset('filename',fullfile(basepath,[S.name '.set']));
S.M     = Get_SM(S.EEG);
S.ch    = [];
S.trial = [];
guidata(S.fh,S);

%Set Child Figure
S.fsp       = figure('units','normalized',...
    'position',[0.025 0 .95 .95],...
    'menubar','none',...
    'toolbar','none',...
    'numbertitle','off',...
    'visible','off',...
    'color',backcolor,...
    'Name','Select channel with mouse button',...
    'resize','off','WindowButtonDownFcn',{@ClickOnWindow,S});

label_list = {S.EEG.chanlocs.labels};

if VARS.HEAD_PLOT
    S.sp          = tmseeg_plottopo (S.EEG.data,S.EEG.chanlocs)';
else
    S.sp          = tmseeg_plottopo (S.EEG.data)';
end
         
guidata(S.fh,S);
N = size(S.M,2);

%Scatter plots
for k = 1:S.EEG.nbchan %find(S.chan)
    if N>100
        warning('off','MATLAB:usev6plotapi:DeprecatedV6ArgumentForFilename')
        PlotScatterChan16(S,k);
    else
%         scatter(S.sp(k),1:N,S.M(k,:),'k.');
        PlotScatterChan16(S,k);
        title(S.sp(k),label_list{k});
    end
    set(S.sp(k),'XLim',[-0.1*N N+N*0.1;],'NextPlot','add');
end
set(findobj('type','scatter'),'Hittest','on')
set(S.sp,'XTickLabel',{' '},'YTickLabel',{' '})

% Setting Deleted elements to red dots
if ~isempty(S.toDelete)
    Del    =  S.toDelete;
    badch  = ismember(Del(:,1),0);
    set(S.sp(Del(badch,2)),'Color',[0.5 0.5 0.5]);
    badtr  = ismember(Del(:,2),0);
    for k  = setdiff(1:S.EEG.nbchan,Del(badch,2))
        bt4ch = [Del(ismember(Del(:,2),k),1); Del(badtr,1)]; 
        p     = flipud(findobj(get(S.sp(k),'Children'),'type','scatter'));
        set(p(bt4ch),'CData',dotcolor)
    end
end

guidata(S.fh,S)
end


%Call EEGLAB function to view data by trial
function [] = pb_eeg_call(varargin)
global TMPREJ basepath

%Data load and Variables
S        = varargin{3};
S        = guidata(S.fh);
S.EEG    = pop_loadset('filename',fullfile(basepath,[S.name '.set']));
S.M      = Get_SM(S.EEG);
S.ch     = [];
S.trial  = [];
guidata(S.fh,S);

S.x         = linspace(0.1,1.9,S.EEG.trials);
evalin('base', 'global TMPREJ');
[~,IX] = sort(mean(S.M),'descend'); %Sort by attribute!!!!!
%data = S.EEG.data(:,:,IX); 
data = S.EEG.data;
eegplot(data,'spacing',100,'srate',S.EEG.srate,'limits',S.EEG.times([1 end]),...
    'winlength',5,'command','eegplot2trial');%,'teastmoneyrue''winrej',[tspan color ~S.toDelete{S.sub}']
waitfor(gcf)

%If Trials were set for deletion, execute
if ~isempty(TMPREJ)
    [trialrej ~] = eegplot2trial( TMPREJ, size(S.EEG.data,2), size(S.EEG.data,3));  %#ok<NASGU>
    caca         = find(trialrej);
    disp(caca)
    N            = numel(caca);
    S.toDelete   = uint16(cat(1,S.toDelete, [caca(:) zeros(N,1)]));
    toDelete     = S.toDelete;
    save(fullfile(basepath,[S.name '_' num2str(S.step_num) '_toDelete.mat']), 'toDelete');
    guidata(S.fh,S);
end

end

%Call Deletion Matrix
function [] = pb_del_matrix_call(varargin)
global basepath backcolor
S = guidata(varargin{1});

% Load EEG, Deletion matrix
[ files, EEG ] = tmseeg_load_step(S.step_num);
[~,name,~] = fileparts(files.name); 

toDelete=[];
if exist(fullfile(basepath,[name '_' num2str(S.step_num) '_toDelete.mat']))
        load(fullfile(basepath,[name '_' num2str(S.step_num) '_toDelete.mat']));
end

% Create Image of Deletion Matrix
image=zeros(EEG.nbchan,EEG.trials);
if ~isempty(toDelete)
    for k=1:size(toDelete,1)
        ch = toDelete(k,2);
        tr = toDelete(k,1);%% column2 channel column1 trial
        if (ch*tr)==0
            if ch==0
                image(:,tr)=1;
            end
            if tr==0
                image(ch,:)=1;
            end
        else
            image(ch,tr) = 1; 
        end
    end
end

figure('menubar','none','Toolbar','none','color',backcolor);
imagesc(image);
xlabel('Trial')
ylabel('Channel')
title('Deletion Matrix (Yellow = marked for deletion)')
end

%Clear Deletion Matrix
function [] = pb_clear_call(varargin)
global basepath
S        = varargin{3};
S        = guidata(S.fh);
    if ~isempty(S.name)
    button = questdlg('Clear Current Subject?','Clear Subject');
        if isequal(button,'Yes')
           S.toDelete = [];
           guidata(S.fh,S);
           toDelete        = S.toDelete;
           save(fullfile(basepath,[S.name '_' num2str(S.step_num) '_toDelete.mat']), 'toDelete');
        end
    end
end

%Delete Selected Trials
function [] = pb_del_tr_ch_call(varargin)
% Calls tmseeg_rm_tagged_elements with the toDelete matrix to remove marked
% channels and trials.  Saves cleaned dataset, toDelete matrix and updates
% parent display
global basepath
S        = varargin{3};
S        = guidata(S.fh);
A        = varargin{4};
[files, EEG] = tmseeg_load_step(S.step_num);
EEG.nbchan_o = EEG.nbchan;
EEG.trials_o = EEG.trials;
try
    disp(exist([basepath '\' S.name '_' num2str(S.step_num) '_toDelete.mat']))
    if exist([basepath '\' S.name '_' num2str(S.step_num) '_toDelete.mat'])
        load(fullfile(basepath,[S.name '_' num2str(S.step_num) '_toDelete.mat']));
    else
        toDelete = [];
    end
[EEG, GC, GT] = tmseeg_rm_tagged_elements(EEG,toDelete);
EEG                = eeg_checkset( EEG );
tmseeg_step_check(files, EEG, A, S.step_num)
save(fullfile(basepath,[S.name '_' num2str(S.step_num) '_toDelete.mat']), 'toDelete');

close
tmseeg_clear_figs()
catch
    error('Could not delete selected data')
end


end

%------------------------------Helper Functions----------------------------

%Matlab 2016 Compatible Scatter Plot - Trial Display
function PlotScatter16(varargin)
S       = varargin{1};
S       = guidata(S.fh);
N = size(S.M,2);
sc = [];
sm = mean(S.M);
if N>100
    warning('off','MATLAB:usev6plotapi:DeprecatedV6ArgumentForFilename')
    for i = 1:N
        sc = [sc scatter('v6',i,sm(i),'ko','filled')]; hold on;
    end
else
    for i = 1:N
        sc = [sc scatter(i,sm(i),'ko','filled')]; hold on;
    end
end

end

%Matlab 2016 Compatible Scatter Plot - Channel Display
function PlotScatterChan16(varargin)
S       = varargin{1};
k       = varargin{2};
S       = guidata(S.fh);
N = size(S.M,2);
sc = [];
if N>100
    warning('off','MATLAB:usev6plotapi:DeprecatedV6ArgumentForFilename')
    for i = 1:N
        sc = [sc scatter('v6',S.sp(k),i,S.M(k,i),'ko','filled')]; hold on;
    end
else
    for i = 1:N
        sc = [sc scatter(S.sp(k),i,S.M(k,i),'ko','filled')]; hold on;
    end
end

end

%Select Window Callback
function ClickOnWindow(varargin)
global points trial
% Called by Plot Channels GUI when window is selected
S       = varargin{3};
S       = guidata(S.fh);
disp(get(gco,'type'))
if isequal(get(gco,'type'),'scatter') %User selects a dot
    points   = flipud(findobj(get(gca,'Children'),'type','scatter'));
    trial    = find(ismember(points,gco));
    S.trial  = trial;
    guidata(S.fh,S);
    tmseeg_plot_Trial(S);
elseif isequal(get(gco,'type'),'axes') %User selects the plot
    points   = flipud(findobj(get(gca,'Children'),'type','scatter'));
    S.ch = find(ismember(S.sp,gco));
    guidata(S.fh,S);
    tmseeg_plot_channel(S);
end
end

%Select Point callback
function button_down_points(varargin)
% Button down function for Plot Trials GUI
global points trial
S         = varargin{3};
S         = guidata(S.fh);
trial   = find(ismember(points,gco));
S.trial = trial;
guidata(S.fh,S);

tmseeg_plot_Trial(S)
end

% Display Attribute Calculation
function SM = Get_SM(EEG)
global VARS
N     = EEG.trials;
ch = EEG.nbchan;
SM    = zeros(EEG.nbchan,N);
findobj('tag','var')
get(findobj('tag','var'),'value')

%Attribute Extraction window, Pulse window
t_st  = find(EEG.times>VARS.TIME_ST,1,'first');
t_end = find(EEG.times<VARS.TIME_END,1,'last');
p_st  = find(EEG.times<VARS.PULSE_ST,1,'last');
p_end = find(EEG.times<VARS.PULSE_END,1,'last');

%Filter Design
Fs=EEG.srate;
ord = 2;
[z1 p1 k1]      = butter(ord,[VARS.FREQ_MIN VARS.FREQ_MAX]/(Fs/2),'bandpass');
[xall1,yall2]   = zp2sos(z1,p1,k1);

switch get(findobj('tag','vv'),'value')
    case 1
        time = [t_st:t_end];
        for trl = 1:N
            EEG_filt = filtfilt(xall1,yall2,double(EEG.data(:,time,trl)));
            SM(:,trl) = log(max(EEG_filt,[],2)-min(EEG_filt,[],2));
        end
    case 2
        time = [t_st:p_st p_end:t_end];
        for trl = 1:N
            EEG_filt = filtfilt(xall1,yall2,double(EEG.data(:,time,trl)));
            SM(:,trl) = log(max(EEG_filt,[],2)-min(EEG_filt,[],2));
        end
    case 3
        time = [t_st:p_st p_end:t_end];
        for trl = 1:N
            EEG_filt = filtfilt(xall1,yall2,double(EEG.data(:,time,trl)));
            SM(:,trl) = log(sum(abs(diff(EEG_filt,1,2)),2));
        end
end
SM = SM*(N/(max(SM(:))-min(SM(:)))) - min(SM(:));
end
