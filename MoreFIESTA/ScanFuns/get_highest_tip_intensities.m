function [ output_args ] = get_highest_tip_intensities(FileName, PathName)
%F Summary of this function goes here
%   Detailed explanation goes here
global ScanOptions
try
    load([PathName FileName]);
    Filament = load([PathName FileName], 'Filament');
    Filament = Filament.Filament;
    Filament = Filament([Filament.Channel]==ScanOptions.ObjectChannel);
    Stack = help_GetStack(PathName, Filament(1).File);
    if ScanOptions.CorrectColor
        for offsetfilename = {'OffSet.mat', 'Offset.mat', 'offset.mat', 'offSet.mat'}
            try
                OffsetMap = load([PathName offsetfilename{1}]);
                break
            catch
            end
        end
        TformChannel = OffsetMap.OffsetMap.T;
    else
        TformChannel = [1 0 0;0 1 0;0 0 1];
    end
    if ScanOptions.CorrectDrift
        try
            Drift = load([PathName 'Drift.mat']);
        catch
            Drift = load([PathName 'drift.mat']);
        end
        Drift = Drift.Drift{ScanOptions.Channel-1};
    else
        Drift = [];
    end
    if ScanOptions.CorrectColor || ScanOptions.CorrectDrift
        [ Stack ] = help_CorrectStack(Stack{1}, Drift, TformChannel );
    end
    [Filament] = help_GetIntensities('get_highest_tip_intensities', Stack, Filament);
    deletefields = setxor(fields(Filament), {'Custom'});
    CroppedFilament = rmfield(Filament, deletefields);
    intensities = cell(length(CroppedFilament),1);
    for i = 1:length(CroppedFilament)
        intensities{i} = CroppedFilament(i).Custom.Intensity;
    end
    save([PathName 'get_highest_tip_intensities.mat'], 'intensities')
catch ME
    warning([[PathName FileName] ': ' ME.identifier])
end

