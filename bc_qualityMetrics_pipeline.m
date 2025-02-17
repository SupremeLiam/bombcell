%% ~~ Example bombcell pipeline ~~
% Adjust the paths in the 'set paths' section and the parameters in bc_qualityParamValues
% This pipeline will:
%   (1) load your ephys data, 
%   (2) decompress your raw data if it is in .cbin format 
%   (3) run bombcell on your data and save the output and
%   (4) bring up summary plots and a GUI to flip through classified cells.
% The first time, this pipeline will be significantly slower (10-20' more)
% than after because it extracts raw waveforms. Subsequent times these
% pre-extracted waveforms are simply loaded in.
% We recommend running this pipeline on a few datasets and deciding on
% quality metric thresholds depending on the summary plots (histograms 
% of the distributions of quality metrics for each unit) and GUI. 


%% set paths - EDIT THESE 
ephysKilosortPath = '/home/netshare/zaru/JF093/2023-03-06/ephys/kilosort2/site1/';% path to your kilosort output files 
ephysRawDir = dir('/home/netshare/zaru/JF093/2023-03-06/ephys/site1/*ap*.*bin'); % path to yourraw .bin or .dat data
ephysMetaDir = dir('/home/netshare/zaru/JF093/2023-03-06/ephys/site1/*ap*.*meta'); % path to your .meta or .oebin meta file
savePath = '/media/julie/ExtraHD/JF093/qMetrics'; % where you want to save the quality metrics 
decompressDataLocal = '/media/julie/ExtraHD/decompressedData'; % where to save raw decompressed ephys data 
gain_to_uV = 0.195; % use this if you are not using spikeGLX or openEphys to record your data. You can then leave ephysMetaDir 
    % empty(e.g. ephysMetaDir = '')
%% load data 
[spikeTimes_samples, spikeTemplates, templateWaveforms, templateAmplitudes, pcFeatures, ...
    pcFeatureIdx, channelPositions] = bc_loadEphysData(ephysKilosortPath);

%% detect whether data is compressed, decompress locally if necessary
rawFile = bc_manageDataCompression(ephysRawDir, decompressDataLocal);

%% which quality metric parameters to extract and thresholds 
param = bc_qualityParamValues(ephysMetaDir, rawFile, ephysKilosortPath, gain_to_uV); 
% param = bc_qualityParamValuesForUnitMatch(ephysMetaDir, rawFile) % Run this if you want to use UnitMatch after

%% compute quality metrics 
rerun = 0;
qMetricsExist = ~isempty(dir(fullfile(savePath, 'qMetric*.mat'))) || ~isempty(dir(fullfile(savePath, 'templates._bc_qMetrics.parquet')));

if qMetricsExist == 0 || rerun
    [qMetric, unitType] = bc_runAllQualityMetrics(param, spikeTimes_samples, spikeTemplates, ...
        templateWaveforms, templateAmplitudes,pcFeatures,pcFeatureIdx,channelPositions, savePath);
else
    [param, qMetric] = bc_loadSavedMetrics(savePath); 
    unitType = bc_getQualityUnitType(param, qMetric, savePath);
end

%% view units + quality metrics in GUI 
% load data for GUI
loadRawTraces = 0; % default: don't load in raw data (this makes the GUI significantly faster)
bc_loadMetricsForGUI;

% GUI guide: 
% left/right arrow: toggle between units 
% g : go to next good unit 
% m : go to next multi-unit 
% n : go to next noise unit
% up/down arrow: toggle between time chunks in the raw data
% u: brings up a input dialog to enter the unit you want to go to
unitQualityGuiHandle = bc_unitQualityGUI(memMapData, ephysData, qMetric, forGUI, rawWaveforms, ...
    param, probeLocation, unitType, loadRawTraces);


%% example: get the quality metrics for one unit
% this is an example to get the quality metric for the unit with the
% original kilosort and phy label of xx (0-indexed), which corresponds to
% the unit with qMetric.clusterID == xx + 1, and to
% qMetric.phy_clusterID == xx . This is *NOT NECESSARILY* the
% (xx + 1)th row of the structure qMetric - some of the  clusters that kilosort
% outputs are empty, because they were dropped in the last stages of the
% algorithm. These empty clusters are not included in the qMetric structure
% there are two ways to do this: 
% 1:
original_id_we_want_to_load = 0;
id_we_want_to_load_1_indexed = original_id_we_want_to_load + 1; 
number_of_spikes_for_this_cluster = qMetric.nSpikes(qMetric.clusterID == id_we_want_to_load_1_indexed);
% or 2:
original_id_we_want_to_load = 0;
number_of_spikes_for_this_cluster = qMetric.nSpikes(qMetric.phy_clusterID == original_id_we_want_to_load);


%% example: get unit labels 
% the output of `uunitType = bc_getQualityUnitType(param, qMetric);` gives
% the unitType in a number format. 1 inidicates good units, 2 inidicates mua units, 3
% indicates non-somatic units and 0 indicates noise units (see below) 
 
goodUnits = unitType == 1;
muaUnits = unitType == 2;
noiseUnits = unitType == 0;
nonSomaticUnits = unitType == 3; 

% example: get all good units number of spikes
all_good_units_number_of_spikes = qMetric.nSpikes(goodUnits);

% (for use with another language: output a .tsv file of labels. You can then simply load this) 
label_table = table(unitType);
writetable(label_table,[savePath filesep 'templates._bc_unit_labels.tsv'],'FileType', 'text','Delimiter','\t');  
      





