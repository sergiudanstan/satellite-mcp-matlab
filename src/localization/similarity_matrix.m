function [sim_matrix, best_match] = similarity_matrix(query_features, ref_features, ref_locations, options)
%SIMILARITY_MATRIX Compute feature similarity matrix for localization
%
%   sim_matrix = similarity_matrix(query, refs) computes similarity between
%   query features and reference database features.
%
%   [sim_matrix, best_match] = similarity_matrix(query, refs, locs) also
%   returns the best matching location.
%
%   Based on the GNSS-denied UAV localization research paper.
%   FSM = beta * F_image * F_location'
%
%   Inputs:
%       query_features - Query image features (1xD or NxD)
%       ref_features   - Reference database features (MxD)
%       ref_locations  - Reference locations [lat, lon] (Mx2)
%       options        - Optional struct with fields:
%           .metric    - 'cosine', 'euclidean', 'correlation' (default: 'cosine')
%           .beta      - Scaling factor (default: 1)
%           .top_k     - Return top-k matches (default: 5)
%           .temperature - Softmax temperature (default: 0.1)
%
%   Outputs:
%       sim_matrix - Similarity matrix (NxM)
%       best_match - Struct with best matching info
%
%   See also: image_matcher, location_encoder, heading_estimator

if nargin < 4
    options = struct();
end

% Get options
metric = get_option(options, 'metric', 'cosine');
beta = get_option(options, 'beta', 1);
top_k = get_option(options, 'top_k', 5);
temperature = get_option(options, 'temperature', 0.1);

% Ensure correct dimensions
if size(query_features, 1) == 1
    query_features = query_features(:)';  % Keep as row vector
end

N = size(query_features, 1);
M = size(ref_features, 1);

% Compute similarity matrix based on metric
switch lower(metric)
    case 'cosine'
        % Normalize features
        query_norm = query_features ./ (sqrt(sum(query_features.^2, 2)) + eps);
        ref_norm = ref_features ./ (sqrt(sum(ref_features.^2, 2)) + eps);

        % Cosine similarity
        sim_matrix = beta * (query_norm * ref_norm');

    case 'euclidean'
        % Negative Euclidean distance (higher is better)
        D = pdist2(query_features, ref_features, 'euclidean');
        sim_matrix = beta * exp(-D / temperature);

    case 'correlation'
        % Pearson correlation
        sim_matrix = zeros(N, M);
        for i = 1:N
            for j = 1:M
                sim_matrix(i, j) = corr(query_features(i,:)', ref_features(j,:)');
            end
        end
        sim_matrix = beta * sim_matrix;

    otherwise
        error('Unknown metric: %s', metric);
end

% Find best matches
if nargout > 1 && nargin >= 3 && ~isempty(ref_locations)
    best_match = struct();

    for i = 1:N
        [sorted_sim, sorted_idx] = sort(sim_matrix(i, :), 'descend');

        % Top-k matches
        top_idx = sorted_idx(1:min(top_k, M));
        top_sim = sorted_sim(1:min(top_k, M));
        top_locs = ref_locations(top_idx, :);

        % Best match
        best_match(i).index = top_idx(1);
        best_match(i).similarity = top_sim(1);
        best_match(i).lat = top_locs(1, 1);
        best_match(i).lon = top_locs(1, 2);

        % Weighted average of top-k (soft localization)
        weights = softmax(top_sim / temperature);
        best_match(i).weighted_lat = sum(weights .* top_locs(:, 1)');
        best_match(i).weighted_lon = sum(weights .* top_locs(:, 2)');

        % Confidence (gap between best and second best)
        if top_k >= 2
            best_match(i).confidence = top_sim(1) - top_sim(2);
        else
            best_match(i).confidence = top_sim(1);
        end

        % All top-k results
        best_match(i).top_k_indices = top_idx;
        best_match(i).top_k_similarities = top_sim;
        best_match(i).top_k_locations = top_locs;
    end
else
    best_match = [];
end

end

function p = softmax(x)
%SOFTMAX Compute softmax probabilities
    x = x - max(x);  % Numerical stability
    exp_x = exp(x);
    p = exp_x / sum(exp_x);
end

function D = pdist2(X, Y, metric)
%PDIST2 Pairwise distance (simplified implementation)
    [N, ~] = size(X);
    [M, ~] = size(Y);
    D = zeros(N, M);

    if strcmp(metric, 'euclidean')
        for i = 1:N
            for j = 1:M
                D(i, j) = sqrt(sum((X(i,:) - Y(j,:)).^2));
            end
        end
    end
end

function val = get_option(options, field, default)
    if isfield(options, field)
        val = options.(field);
    else
        val = default;
    end
end
