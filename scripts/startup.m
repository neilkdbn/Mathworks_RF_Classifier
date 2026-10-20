%STARTUP Project startup — runs automatically when RFClassifier.prj opens.
% Adds core folders to the path (idempotent) so scripts run from any cwd.
thisDir = fileparts(mfilename('fullpath'));
rootDir  = fileparts(thisDir);
for f = ["scripts", "utilities", "tests", "preprocessing", "deep_learning"]
    p = fullfile(rootDir, f);
    if isfolder(p), addpath(p); end
end
clear thisDir rootDir f p;
