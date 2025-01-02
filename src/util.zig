const std = @import("std");

/// Reads lines from `inputs/${inputFileName}`, then passes each line to `parseLine`
/// and returns a slice of the return values.
///
/// The caller owns the slice of results and must free it.
///
/// The slices passed to `parseLine` *do not live beyond the end of `readInputFileLines`*
/// and must be copied if you want to use them after `readInputFileLines` is finished.
pub fn readInputFileLines(
    comptime ParserResult: type,
    allocator: std.mem.Allocator,
    inputFileName: []const u8,
    parseLine: *const fn (allocator: std.mem.Allocator, line: []const u8) anyerror!ParserResult,
) ![]ParserResult {
    // Get directory of running program executable
    const exe_path = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_path);

    const exe_dir = std.fs.path.dirname(exe_path) orelse ".";

    // Now use that to get the input file's path
    const file_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "..", "inputs", inputFileName });
    defer allocator.free(file_path);

    // Open the input file
    const file = try std.fs.openFileAbsolute(file_path, .{});
    defer file.close();

    // Read the entire contents
    const file_contents = try file.readToEndAlloc(allocator, 1024 * 1024 * 16);
    defer allocator.free(file_contents);

    var lines_iterator = std.mem.tokenizeAny(u8, file_contents, "\n\r");

    // Collect the parsed lines in an ArrayList
    var parsed_lines = std.ArrayList(ParserResult).init(allocator);

    while (lines_iterator.next()) |line| {
        try parsed_lines.append(try parseLine(allocator, line));
    }

    // Return the results as a slice
    return parsed_lines.toOwnedSlice();
}

/// Increment `key` within `map` by `n` if it exists, otherwise set it to `n`.
pub fn mapInc(comptime K: type, comptime V: type, map: *std.AutoHashMap(K, V), key: K, n: V) !void {
    if (!map.contains(key)) {
        try map.put(key, n);
    } else {
        const existing = map.get(key).?;
        map.putAssumeCapacity(key, existing + n);
    }
}

/// Print all the entries in `map` out to stderr.
pub fn printMap(comptime K: type, comptime V: type, map: std.AutoHashMap(K, V)) void {
    var iter = map.iterator();
    while (iter.next()) |entry| {
        std.debug.print("- {any}: {any}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

pub fn AStarConfig(
    comptime Node: type,
    comptime Context: type,
    comptime Score: type,
) type {
    return struct {
        fn equalWeight(_: *const Context, _: Node, _: Node) Score {
            return 1;
        }

        /// Where to start the path search from
        start: Node,

        /// Holds any additional data the callbacks below might need to compute their results
        context: Context,

        /// The maximum amount of neighbours that `get_neighbours` will ever need to store
        max_neighbours: usize,

        /// Gets the distance from `node` to the destination we are trying to create a path to
        ///
        /// If this returns `0` then the destination has been reached and it will return the best paths found
        get_distance: *const fn (context: *const Context, node: Node) Score,

        /// Gets the difficulty score of going from node `from` to node `to`
        ///
        /// By default equal weighting is used, i.e. the difficulty from any node to any other node is the same
        get_weight: *const fn (context: *const Context, from: Node, to: Node) Score = equalWeight,

        /// Gets all nodes that can be reached from `node`, storing them inside `results`
        ///
        /// Results should be stored at the beginning of `results` (i.e. caller can assume there are no more results past the first `null` element)
        ///
        /// (`results` is allocated to be large enough to store `max_neighbours` results and
        /// is always filled with `null` before this function is called)
        get_neighbours: *const fn (context: *const Context, node: Node, results: []?Node) void,
    };
}

/// Generic A* search algorithm implementation.
/// Returns all paths to the end with the lowest possible score.
pub fn aStarSearch(
    comptime Node: type,
    comptime Context: type,
    comptime Score: type,
    allocator: std.mem.Allocator,
    config: AStarConfig(Node, Context, Score),
) ![][]Node {
    const start = config.start;

    const neighbours = try allocator.alloc(?Node, config.max_neighbours);
    defer allocator.free(neighbours);

    var came_from = std.AutoHashMap(Node, std.ArrayList(Node)).init(allocator);
    defer came_from.deinit();
    defer {
        var iter = came_from.valueIterator();
        while (iter.next()) |list| {
            list.deinit();
        }
    }

    var g_scores = std.AutoHashMap(Node, Score).init(allocator);
    defer g_scores.deinit();
    try g_scores.put(start, 0);

    var f_scores = std.AutoHashMap(Node, Score).init(allocator);
    defer f_scores.deinit();
    try f_scores.put(start, config.get_distance(&config.context, start));

    const compare_context = CompareNodesContext(Node, Score){ .f_scores = &f_scores };
    var open_set = std.PriorityQueue(
        Node,
        CompareNodesContext(Node, Score),
        compareNodes(Node, Score),
    ).init(allocator, compare_context);
    defer open_set.deinit();
    try open_set.add(start);

    // While there are still nodes we can visit...
    while (open_set.count() > 0) {
        const current = open_set.remove();

        // If we have reached the end...
        if (config.get_distance(&config.context, current) == 0) {
            // Keeps track of all possible paths from start to end
            var all_paths = std.ArrayList([]Node).init(allocator);
            errdefer all_paths.deinit();
            errdefer {
                for (all_paths.items) |path| {
                    allocator.free(path);
                }
            }

            // Starting from the end...
            var path = std.ArrayList(Node).init(allocator);
            try path.append(current);

            // Keeps track of each partial path from start to end
            const FrontierItem = struct {
                node: Node,
                path: std.ArrayList(Node),
            };
            var frontier = std.ArrayList(FrontierItem).init(allocator);
            defer frontier.deinit();
            try frontier.append(.{ .node = current, .path = path });

            while (frontier.items.len > 0) {
                const item = frontier.orderedRemove(0);
                defer item.path.deinit();
                const next_nodes = came_from.get(item.node).?;

                for (next_nodes.items) |next_node| {
                    var new_path = try item.path.clone();
                    errdefer new_path.deinit();
                    try new_path.append(next_node);

                    if (std.meta.eql(next_node, start)) {
                        const complete_path = try new_path.toOwnedSlice();
                        errdefer allocator.free(complete_path);
                        std.mem.reverse(Node, complete_path);
                        try all_paths.append(complete_path);
                    } else {
                        try frontier.append(.{ .node = next_node, .path = new_path });
                    }
                }
            }

            return all_paths.toOwnedSlice();
        }

        const g_score = g_scores.get(current).?;

        @memset(neighbours, null);
        config.get_neighbours(&config.context, current, neighbours);

        for (neighbours) |maybe_neighbour| {
            if (maybe_neighbour == null) {
                break;
            }

            const neighbour = maybe_neighbour.?;
            const tent_g_score = g_score + config.get_weight(&config.context, current, neighbour);
            const maybe_neighbour_g_score = g_scores.get(neighbour);

            // If this is strictly a better way to get to neighbour...
            if (maybe_neighbour_g_score == null or tent_g_score < maybe_neighbour_g_score.?) {
                // De-allocate any worse ways, if there were any
                if (came_from.getPtr(neighbour)) |inferior_list| {
                    inferior_list.deinit();
                }

                // Set best path to neighbour to be from this node.
                var list = std.ArrayList(Node).init(allocator);
                try list.append(current);
                try came_from.put(neighbour, list);

                // Update neighbours risk and score.
                try g_scores.put(neighbour, tent_g_score);
                try f_scores.put(neighbour, tent_g_score + config.get_distance(&config.context, neighbour));

                // Add the neighbour to the open set if it isn't already
                for (open_set.items) |node| {
                    if (std.meta.eql(node, neighbour)) {
                        break;
                    }
                } else {
                    try open_set.add(neighbour);
                }
            } else if (maybe_neighbour_g_score.? == tent_g_score) {
                // This path to neighbour is equally as good as the other path to neighbour
                var list = came_from.getPtr(neighbour).?;
                try list.append(current);
            }
        }
    }

    return &[0][]Node{};
}

fn CompareNodesContext(Node: type, Score: type) type {
    return struct {
        f_scores: *const std.AutoHashMap(Node, Score),
    };
}

fn compareNodes(Node: type, Score: type) fn (CompareNodesContext(Node, Score), Node, Node) std.math.Order {
    return (struct {
        fn compare(context: CompareNodesContext(Node, Score), a: Node, b: Node) std.math.Order {
            const a_f_score = context.f_scores.get(a).?;
            const b_f_score = context.f_scores.get(b).?;
            return std.math.order(a_f_score, b_f_score);
        }
    }).compare;
}
