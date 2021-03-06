function [f] = fJKplotframework(Tracks, type, isfrequencyplot, events, Options)
%plotmodes: 0: X vs Y plot, 1: Events along X during Y, 2: filament end plot
additionalplots = 1;
if additionalplots>1
    mainfig=gcf;
    statfig=figure('Name',[get(mainfig, 'Name') '_STATS'], 'Tag','Plot');
    figure(mainfig);
end
subplot = @(m,n,p) subtightplot (m, n, p, [0.08 0.11], [0.08 0.08], [0.08 0.02]);
[label_x, label_y, DelTracks] = SetUpMode(isfrequencyplot, events, [Tracks.PreviousEvent]', Options);
[uniquetype, ~, idvec] = unique(type,'stable');
if isfrequencyplot == 1
    for i = 1:length(uniquetype)
        if ~any(events(idvec==i)) %find all types without events and remove their tracks
            DelTracks = DelTracks | idvec==i;
        end
    end
end
if  any(DelTracks)
    Tracks(DelTracks) = [];
    events(DelTracks) = [];
    type(DelTracks) = [];
    [uniquetype] = unique(type,'stable');
end
ntypes = length(uniquetype);
for j=1:ntypes    %Loop through all groups to be plotted, each group gets its own subplot
    if j>1 && ~isvalid(f)
        return
    end
    curent_y_label = '';
    curent_x_label = '';
    switch ntypes
        case {1,2,3,4,5}
            f=subplot(1,ntypes,j);
            if j==1
                curent_y_label = label_y;
            end
            curent_x_label = label_x;
        case 6
            f=subplot(2,3,j);
            if j==1 || j==4
                curent_y_label = label_y;
            end
            if j > 3
                curent_x_label = label_x;
            end
        case {7, 8}
            f=subplot(2,4,j);
            if j==1 || j==5
                curent_y_label = label_y;
            end
            if j > 4
                curent_x_label = label_x;
            end
        case {9, 10}
            f=subplot(2,5,j);
            if j==1 || j==6
                curent_y_label = label_y;
            end
            if j > 5
                curent_x_label = label_x;
            end
        case {11, 12}
            f=subplot(2,6,j);
            if j==1 || j==7
                curent_y_label = label_y;
            end
            if j > 6
                curent_x_label = label_x;
            end
        otherwise
            msgbox('that would be more than 12 plots! Try checking the "Only selected" checkbox');
            return
    end
    hold on;
    correct_type=cellfun(@(x) strcmp(x, uniquetype(j)),type);
    PlotTracks=Tracks(correct_type);
    if additionalplots==2
        figure(statfig);
        fqq=subplot(1,ntypes,j);
        axes(fqq);drawnow;
        qqplot(plot_x,plot_y);drawnow;
        figure(mainfig);
        axes(f);drawnow;
    end
    switch isfrequencyplot
        case 0
            [plot_x, plot_y, ~] = Get_Vectors(PlotTracks, events(correct_type), Options.mXReference.val, isfrequencyplot, Options.cExclude.val);
            point_info=cell(sum(correct_type),1);
            if Options.ZOK
                color_mode = 1;
                for k=1:sum(correct_type)
                    point_info{k}=PlotTracks(k).Z(1+Options.cExclude.val:end-Options.cExclude.val);
                end
                point_info=vertcat(point_info{:});
            else
                color_mode = 0;
                if Options.cGroupIntoMTs.val
                    [legend_items, ~, object_name_ids] = unique({PlotTracks.Name}, 'stable');
                    for k=1:sum(correct_type)
                        point_info{k}=repmat(object_name_ids(k),size(PlotTracks(k).X(1+Options.cExclude.val:end-Options.cExclude.val)),1);
                    end
                    point_info=vertcat(point_info{:}); %point_info simply carries information about to which track a point belongs
                else
                    legend_items = {PlotTracks.Name};
                    for k=1:sum(correct_type)
                        point_info{k}=repmat(k,[size(PlotTracks(k).X(1+Options.cExclude.val:end-Options.cExclude.val)),1]);
                    end
                    point_info=vertcat(point_info{:});
                end
            end
            fJKscatterboxplot(plot_x, plot_y, point_info, color_mode);
            if Options.cLegend.val
                legend(legend_items, 'Interpreter', 'none', 'Location', 'best');
            else
                legend('hide');
            end
            if isfield(Options, 'FilamentEndPlot')
                if Options.FilamentEndPlot.has_err_fun_format
                    try
                        [fitresult, gof] = FitErf(plot_x, plot_y);
                        % Plot fit with data.
                        plot( fitresult, 'k-');
                    catch
                    end
                end
            end
        case 1
            [plot_x, plot_y, ploteventends] = Get_Vectors(PlotTracks, events(correct_type), Options.mXReference.val, isfrequencyplot, Options.cExclude.val);
            fJKfrequencyvsXplot(plot_x, plot_y, ploteventends, {Options.lPlot_XVar.str, Options.lPlot_YVar.str});
    end
    set(gca, 'FontSize', 16, 'LabelFontSizeMultiplier', 1.5);
    title(uniquetype{j}, 'FontSize', 18);
    xlabel(curent_x_label);
    ylabel([curent_y_label]);
end


function [plotx, ploty, ploteventends] = Get_Vectors(PlotTracks, plotevents, refmode, isfrequencyplot, exclude)
%plotx and ploty are vectors with all datapoints of the group to be plotted
pr = length(PlotTracks);
cellx=cell(pr,1);
celly=cell(pr,1);
ploteventends=nan(size(plotevents));
if isfrequencyplot
    switch refmode
        case {1,5}
        for k=1:pr
            cellx{k}=PlotTracks(k).X;
            diffy=diff(PlotTracks(k).Y);
            celly{k}=[diffy(1)/2; (diffy(1:end-1)+diffy(2:end))/2; diffy(end)/2];
            if plotevents(k)
                if isnan(PlotTracks(k).X(end))
                    ploteventends(k)=PlotTracks(k).X(max(2,end-2));
                else
                    ploteventends(k)=PlotTracks(k).X(end);
                end
            end
        end
        case {2, 6}
        for k=1:pr
            cellx{k}=PlotTracks(k).X-PlotTracks(k).X(1);
            diffy=diff(PlotTracks(k).Y);
            celly{k}=[diffy(1)/2; (diffy(1:end-1)+diffy(2:end))/2; diffy(end)/2];
            if plotevents(k)
                ploteventends(k)=PlotTracks(k).X(end)-PlotTracks(k).XEventStart;
            end
        end
        case {3, 7}
        for k=1:pr
            cellx{k}=PlotTracks(k).X-PlotTracks(k).X(end);
            diffy=diff(PlotTracks(k).Y);
            celly{k}=[diffy(1)/2; (diffy(1:end-1)+diffy(2:end))/2; diffy(end)/2];
            if plotevents(k)
                ploteventends(k)=PlotTracks(k).X(1)-PlotTracks(k).XEventEnd;
            end
        end
        case 4
        for k=1:pr
            cellx{k}=PlotTracks(k).X-nanmedian(PlotTracks(k).X);
            diffy=diff(PlotTracks(k).Y);
            celly{k}=[diffy(1)/2; (diffy(1:end-1)+diffy(2:end))/2; diffy(end)/2];
            if plotevents(k)
                ploteventends(k)=PlotTracks(k).X(1)-nanmedian(PlotTracks(k).X);
            end
        end
    end
else
    switch refmode
        case {1,5}
        for k=1:pr
            cellx{k}=PlotTracks(k).X(1+exclude:end-exclude);
        end
        case {2, 6}
        for k=1:pr
            cellx{k}=PlotTracks(k).X(1+exclude:end-exclude)-PlotTracks(k).XEventStart;
        end
        case {3, 7}
        for k=1:pr
            cellx{k}=PlotTracks(k).X(1+exclude:end-exclude)-PlotTracks(k).XEventEnd;
        end
        case 4
        for k=1:pr
            cellx{k}=PlotTracks(k).X(1+exclude:end-exclude)-nanmedian(PlotTracks(k).X);
        end
    end
    for k=1:pr
        celly{k}=PlotTracks(k).Y(1+exclude:end-exclude);
    end
end
plotx=vertcat(cellx{:});
ploty=vertcat(celly{:});

function [labelx, labely, DelTracks] = SetUpMode(plot_mode, events, previous_event, Options)
DelTracks = false(length(events),1);
switch Options.mXReference.val
    case 1
        labelsuffixx='';
    case 2
        labelsuffixx='- start (with events only)';
        DelTracks = DelTracks | ~previous_event;
    case 3
        labelsuffixx='- end (with events only)';
        DelTracks = DelTracks | ~events';
    case 4
        labelsuffixx='- median';
    case 5
        labelsuffixx='- track velocity';
    case 6
        labelsuffixx='- start';
    case 7
        labelsuffixx='- end';
end
if plot_mode == 1
    labelprefixy='N(events)/';
    unitprefixy='1/';
else
    labelprefixy='';
    unitprefixy='';
end
if strcmp(Options.lSubsegment.print, 'All') || Options.cPlotGrowingTracks.val==1
    segment = '';
else
    segment =  [' (' Options.lSubsegment.print ' only)'];
end
labelx=[Options.lPlot_XVar.print ' ' labelsuffixx ' [' Options.lPlot_XVar.str ']'];
labely=[labelprefixy Options.lPlot_YVar.print segment ' [' unitprefixy Options.lPlot_YVar.str ']'];