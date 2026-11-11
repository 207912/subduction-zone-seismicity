function summary = plot_cross_sections()
%PLOT_CROSS_SECTIONS Plot distance-depth profiles from five USGS catalogues.
% Returns region names, plotted event counts and maximum depths in km.

dataFolder = fullfile(fileparts(mfilename('fullpath')), 'data');
profiles = readtable(fullfile(dataFolder, 'profiles.csv'), 'TextType', 'string');
kmPerDegree = 2 * pi * 6371 / 360;
eventCounts = zeros(height(profiles), 1);
maxDepths = NaN(height(profiles), 1);

for k = 1:height(profiles)
    profile = profiles(k, :);
    catalog = readtable(fullfile(dataFolder, profile.id + ".csv"), ...
        'TextType', 'string');
    events = catalog(strcmpi(catalog.type, "earthquake"), :);
    span = profile.end_deg - profile.start_deg;

    if profile.coordinate == "longitude"
        % Eastward offsets stay continuous across the antimeridian.
        scale = kmPerDegree * cosd(profile.reference_latitude_deg);
        distance = mod(events.longitude - profile.start_deg, 360) * scale;
        width = mod(span, 360) * scale;
    else
        distance = (events.latitude - profile.start_deg) * kmPerDegree;
        width = span * kmPerDegree;
    end

    depth = events.depth;
    visible = isfinite(distance) & isfinite(depth) & ...
        distance >= 0 & distance <= width & depth >= 0 & depth <= 700;
    eventCounts(k) = nnz(visible);
    if eventCounts(k) > 0
        maxDepths(k) = max(depth(visible));
    end

    figure('Color', 'w', 'Name', char(profile.region));
    scatter(distance(visible), depth(visible), 16, [0.08 0.34 0.56], 'filled');
    axis equal;
    set(gca, 'YDir', 'reverse');
    xlim([0 width]);
    ylim([0 700]);
    grid on;
    box on;
    xlabel(profile.distance_label);
    ylabel('Depth (km)');
    title(profile.region + " | Wadati-Benioff zone");
end

summary = table(profiles.region, eventCounts, maxDepths, ...
    'VariableNames', {'Region', 'EarthquakeCount', 'MaxDepthKm'});
end
