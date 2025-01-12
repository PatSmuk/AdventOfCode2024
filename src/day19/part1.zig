const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day19.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    const patterns = blk: {
        var temp = std.ArrayList([]const u8).init(allocator);
        defer temp.deinit();
        var iter = std.mem.tokenizeSequence(u8, lines[0], ", ");
        while (iter.next()) |token| {
            try temp.append(token);
        }
        const temp_slice = try temp.toOwnedSlice();
        break :blk temp_slice;
    };
    defer allocator.free(patterns);

    var total_possible: usize = 0;

    for (1..lines.len) |i| {
        const target = lines[i];
        const config = SearchConfig.findPathConfig(patterns, target);
        const path = try util.findOnePath(SearchConfig.Node, SearchConfig.Context, SearchConfig.Score, allocator, config);
        defer allocator.free(path);

        // std.debug.print("{s}: ", .{target});

        if (path.len == 0) {
            // std.debug.print("no path\n", .{});
            continue;
        }

        total_possible += 1;

        // for (path[1..]) |step| {
        //     std.debug.print("{s} -> ", .{step});
        // }
        // std.debug.print("{s}\n", .{target});
    }

    std.debug.print("{d}", .{total_possible});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

const SearchConfig = struct {
    const Node = []const u8;
    const Context = struct {
        patterns: [][]const u8,
        target: []const u8,
    };
    const Score = usize;

    fn getDistance(context: *const Context, key: Node) Score {
        return context.target.len - key.len;
    }

    fn getNeighbours(context: *const Context, key: Node, results: []?Node) void {
        var results_i: usize = 0;
        const remaining_target = context.target[key.len..];
        std.debug.assert(remaining_target.len > 0);

        for (context.patterns) |pattern| {
            if (pattern.len <= remaining_target.len and std.mem.eql(u8, pattern, remaining_target[0..pattern.len])) {
                results[results_i] = context.target[0..(key.len + pattern.len)];
                results_i += 1;
            }
        }
    }

    fn findPathConfig(patterns: [][]const u8, target: []const u8) util.FindPathConfig(Node, Context, Score) {
        return .{
            .start = "",
            .max_neighbours = patterns.len,
            .context = Context{ .patterns = patterns, .target = target },
            .get_distance = getDistance,
            .get_neighbours = getNeighbours,
        };
    }
};
