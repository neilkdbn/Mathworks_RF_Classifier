function proj = setupRFClassifierProject(rootFolder)
%SETUPRFCLASSIFIERPROJECT Create (or repair) the formal MATLAB Project.
%   PROJ = SETUPRFCLASSIFIERPROJECT() creates/opens the "RF Classifier"
%   MATLAB Project in the folder containing this script's parent, using
%   matlab.project.createProject with merge-friendly FixedPathMultiFile
%   definition files. It registers scripts/utilities/tests on the project
%   path, wires the project startup file, and addsConvention shortcuts.
%
%   Run once per clone in MATLAB:
%       addpath('scripts'); setupRFClassifierProject()
%
%   Input (optional): ROOTFOLDER - project root (default: parent of scripts/).
%   Output: PROJ - matlab.project.Project object.
%
%   100% MATLAB. No Python.
%
%   Team: Anjali (integration owner). Consumers: Neil, Arya, Shreeya.

if nargin < 1 || isempty(rootFolder)
    here = fileparts(mfilename('fullpath'));   % .../scripts
    rootFolder = fileparts(here);              % project root
end

% Folders that belong on the MATLAB/project path (tracked source).
pathFolders = {'scripts', 'utilities', 'tests', 'preprocessing', 'deep_learning'};
% Folders tracked by the project but NOT on the path (artifacts/docs).
trackedFolders = {'data', 'models', 'docs'};

% Reuse the open project if it already points at this root.
proj = matlab.project.currentProject();
needsCreate = isempty(proj.Name) || ~strcmp(proj.RootFolder, rootFolder);
if needsCreate
    % If a stale .prj scaffold exists, MATLAB upgrades it in place;
    % if creation fails because one exists, open it instead.
    try
        proj = matlab.project.createProject("Name", "RF Classifier", ...
            "Folder", rootFolder, ...
            "DefinitionFilesType", "FixedPathMultiFile");
    catch ME
        if isfolder(fullfile(rootFolder, 'resources', 'project')) ...
                || isfile(fullfile(rootFolder, 'RFClassifier.prj'))
            proj = openProject(rootFolder);
        else
            rethrow(ME);
        end
    end
end

proj.Name = "RF Classifier";
proj.Description = "Software-only RF signal classification pipeline: " + ...
    "synthetic RF dataset generation, channel impairment, feature " + ...
    "extraction, and deep-learning modulation classification. 100% MATLAB.";

% Create folders on disk if missing.
for f = [pathFolders, trackedFolders]
    d = fullfile(rootFolder, f{1});
    if ~isfolder(d), mkdir(d); end
end

% Track folders + put source folders on the project path.
% RULE: every tracked folder on the path needs BOTH addFolderIncludingChildFiles
% AND addPath, else runChecks fails with Project:Checks:ProjectPath.
for f = [pathFolders, trackedFolders]
    d = fullfile(rootFolder, f{1});
    try addFolderIncludingChildFiles(proj, d); catch, end %#ok<CTCH>
end
for f = pathFolders
    try addPath(proj, fullfile(rootFolder, f{1})); catch, end %#ok<CTCH>
end

% Project startup file (runs on project open).
startupFile = fullfile(rootFolder, 'scripts', 'startup.m');
if isfile(startupFile)
    try addStartupFile(proj, startupFile); catch, end %#ok<CTCH>
end

% Shortcuts for the team's daily workflow.
addShortcutSafe(proj, fullfile(rootFolder, 'scripts', 'mainRFClassifier.m'));
addShortcutSafe(proj, fullfile(rootFolder, 'scripts', 'setupRFClassifierProject.m'));
addShortcutSafe(proj, fullfile(rootFolder, 'tests', 'testPipelineSmoke.m'));

% Git integration is automatic when the root is a git repo (this repo is).
fprintf('RF Classifier project ready at %s\n', proj.RootFolder);
fprintf('  DefinitionFilesType: %s\n', string(proj.DefinitionFilesType));
fprintf('Open with: openProject(''%s'')\n', proj.RootFolder);
end

function addShortcutSafe(proj, filePath)
if isfile(filePath)
    try addShortcut(proj, filePath); catch, end %#ok<CTCH>
end
end
