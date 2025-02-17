function ephysProperties = bc_computeAllEphysProperties(spikeTimes_samples, spikeTemplates, templateWaveforms_whitened, winv, paramEP, savePath)

ephysProperties = struct;
uniqueTemplates = unique(spikeTemplates);
spikeTimes = spikeTimes_samples ./ paramEP.ephys_sample_rate; %convert to seconds after using sample indices to extract raw waveforms
%timeChunks = min(spikeTimes):param.deltaTimeChunk:max(spikeTimes);
[maxChannels, templateWaveforms] = bc_getWaveformMaxChannelEP(templateWaveforms_whitened, winv);
%% loop through units and get ephys properties
% QQ divide in time chunks , add plotThis 

fprintf('\n Extracting ephys properties ... ')

for iUnit = 1:length(uniqueTemplates)
    clearvars thisUnit theseSpikeTimes theseAmplis
    thisUnit = uniqueTemplates(iUnit);
    ephysProperties.clusterID(iUnit) = thisUnit;
    theseSpikeTimes = spikeTimes(spikeTemplates == thisUnit);

    %% compute ACG
    ephysProperties.acg(iUnit, :) = bc_computeACG(theseSpikeTimes, paramEP.ACGbinSize, paramEP.ACGduration, paramEP.plotThis);
    
    %% compute post spike suppression
    ephysProperties.postSpikeSuppression(iUnit) = bc_computePSS(ephysProperties.acg(iUnit, :));

    %% compute template duration
    ephysProperties.templateDuration(iUnit) = bc_computeTemplateWaveformDuration(templateWaveforms(thisUnit, :, maxChannels(iUnit)),...
        paramEP.ephys_sample_rate);
    
    %% compute firing rate
    ephysProperties.spike_rateSimple(iUnit) = bc_computeFR(theseSpikeTimes);

    %% compute proportion long ISIs
    ephysProperties.propLongISI(iUnit) = bc_computePropLongISI(theseSpikeTimes, paramEP.longISI);

    %% cv, cv2

    %% Fano factor

    %% skewISI

    %% max firing rate

    %% bursting things
    if ((mod(iUnit, 100) == 0) || iUnit == length(uniqueTemplates)) && paramEP.verbose
       fprintf(['\n   Finished ', num2str(iUnit), ' / ', num2str(length(uniqueTemplates)), ' units.']);
    end
end

%% save ephys properties
fprintf('\n Finished extracting ephys properties')
try
    bc_saveEphysProperties(paramEP, ephysProperties, savePath);
    fprintf('\n Saved ephys properties to %s \n', savePath)
    %% get some summary plots
    
catch
    warning('\n Warning, ephys properties not saved! \n')
end
%% plot
paramEP.plotThis=0;
if paramEP.plotThis
    % QQ plot histograms of each metric with the cutoffs set in params
    figure();
    subplot(311)
    scatter(abs(ephysProperties.templateDuration), ephysProperties.postSpikeSuppression);
    xlabel('waveform duration (us)')
    ylabel('post spike suppression')
    makepretty;
    
    subplot(312)
    scatter(ephysProperties.postSpikeSuppression, ephysProperties.propLongISI);
    xlabel('post spike suppression')
    ylabel('prop long ISI')
    makepretty;

    subplot(313)
    scatter(abs(ephysProperties.templateDuration), ephysProperties.propLongISI);
    xlabel('waveform duration (us)')
    ylabel('prop long ISI')
    makepretty;
end


end