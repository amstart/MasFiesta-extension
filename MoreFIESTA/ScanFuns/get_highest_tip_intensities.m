function [ output_args ] = get_highest_tip_intensities(FileName, PathName)
%F Summary of this function goes here
%   Detailed explanation goes here
global ScanOptions
load([PathName FileName]);
Filament = load([PathName FileName], 'Filament');
Filament = Filament.Filament;
Filament = Filament([Filament.Channel]==ScanOptions.ObjectChannel);
StackName = strrep(Filament(1).File, ScanOptions.ReplaceFileNamePattern{1}, ScanOptions.ReplaceFileNamePattern{2});
fileseps = findstr(PathName, filesep);
[Stack,~,~]=fStackRead([PathName(1:fileseps(end-1)) StackName]);
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
[ CorrectedStack ] = help_CorrectStack(Stack{1}, Drift, TformChannel );
[Filament] = help_GetIntensities('get_highest_tip_intensities', CorrectedStack, Filament);
deletefields = setxor(fields(Filament), {'Custom'});
CustomField = rmfield(Filament, deletefields);
save([PathName 'get_highest_tip_intensities.mat'], 'CustomField')
end

