function [intext, indata] = csvread_with_headers(filename)
%CSVREAD_WITH_HEADERS  Read a CSV whose first row is column headers.
%   [INTEXT, INDATA] = CSVREAD_WITH_HEADERS(FILENAME) reads a comma-separated
%   file in which the first row holds text column headers and the remaining
%   rows hold numeric data.
%
%     INTEXT  - cell array of the raw cells; INTEXT(1,:) is the header row.
%     INDATA  - numeric matrix of the data rows (header row excluded).
%
%   This mirrors the small Branson/FlyBowl helper of the same name that
%   ReadStimulusProtocol expects (it uses INTEXT(1,:) as the protocol header
%   and INDATA(:,k) as the numeric step columns) but which is not shipped in
%   this repo. Implemented on readcell so it works on current MATLAB.

C = readcell(filename);
intext = C;

if size(C,1) < 2,
  indata = [];
  return;
end

data = C(2:end,:);
indata = nan(size(data));
for k = 1:numel(data),
  x = data{k};
  if isnumeric(x) || islogical(x),
    indata(k) = double(x);
  elseif ischar(x) || isstring(x),
    indata(k) = str2double(x);
  end
  % anything else (e.g. missing) stays NaN
end
