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

    var total_ways: usize = 0;

    for (lines[1..]) |line| {
        const ways = try calculateTotalPaths(allocator, line, patterns);
        std.debug.print("{s}: {?d}\n", .{ line, ways });

        if (ways != null) {
            total_ways += ways.?;
        }
    }

    std.debug.print("{d}", .{total_ways});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn calculateTotalPaths(allocator: std.mem.Allocator, line: []const u8, patterns: [][]const u8) !?usize {
    var ways_to_reach_state = std.StringHashMap(usize).init(allocator);
    defer ways_to_reach_state.deinit();
    try ways_to_reach_state.put("", 1);

    for (0..line.len) |i| {
        const ways = ways_to_reach_state.get(line[0..i]);
        if (ways == null) {
            continue;
        }

        for (patterns) |pattern| {
            if (i + pattern.len > line.len) {
                continue;
            }
            if (std.mem.eql(u8, line[i..(i + pattern.len)], pattern)) {
                const key = line[0..(i + pattern.len)];
                try util.mapInc(&ways_to_reach_state, key, ways.?);
            }
        }
    }

    return ways_to_reach_state.get(line);
}
