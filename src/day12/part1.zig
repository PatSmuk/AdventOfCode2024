const std = @import("std");
const util = @import("util");

const Location = struct { row: usize, col: usize };
const Edge = [2]Location;

const DirectionVector = [2]i8;

const direction_vectors = [_]DirectionVector{
    .{ 0, -1 }, // up
    .{ 1, 0 }, // right
    .{ 0, 1 }, // down
    .{ -1, 0 }, // left
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try util.readInputFileLines([]u8, allocator, "day12.txt", parseLine);
    defer allocator.free(grid);
    defer {
        for (grid) |line| {
            allocator.free(line);
        }
    }

    var visited_locations = std.AutoHashMap(Location, void).init(allocator);
    defer visited_locations.deinit();

    var total_cost: u32 = 0;

    for (0..grid.len) |row| {
        for (0..grid[0].len) |col| {
            if (visited_locations.contains(.{ .row = row, .col = col })) {
                continue;
            }

            total_cost += try calculateCost(allocator, grid, row, col, &visited_locations);
        }
    }

    std.debug.print("{d}", .{total_cost});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn calculateCost(allocator: std.mem.Allocator, grid: [][]const u8, start_row: usize, start_col: usize, visited_locations: *std.AutoHashMap(Location, void)) !u32 {
    const plant_type = grid[start_row][start_col];

    var area: u32 = 0;

    var frontier = std.ArrayList(Location).init(allocator);
    defer frontier.deinit();
    try frontier.append(.{ .row = start_row, .col = start_col });

    var edge_counts = std.AutoHashMap(Edge, u2).init(allocator);
    defer edge_counts.deinit();

    while (frontier.items.len > 0) {
        const loc = frontier.pop();
        const row = loc.row;
        const col = loc.col;

        if (visited_locations.contains(loc)) {
            continue;
        }
        try visited_locations.put(loc, {});

        area += 1;

        // #--1-->X
        // |      |  # = (row,col)
        // 3      4
        // |      |
        // V      V
        // X--2-->X

        // 1
        try util.mapInc(&edge_counts, [2]Location{ .{ .row = row, .col = col }, .{ .row = row, .col = col + 1 } }, 1);
        // 2
        try util.mapInc(&edge_counts, [2]Location{ .{ .row = row + 1, .col = col }, .{ .row = row + 1, .col = col + 1 } }, 1);
        // 3
        try util.mapInc(&edge_counts, [2]Location{ .{ .row = row, .col = col }, .{ .row = row + 1, .col = col } }, 1);
        // 4
        try util.mapInc(&edge_counts, [2]Location{ .{ .row = row, .col = col + 1 }, .{ .row = row + 1, .col = col + 1 } }, 1);

        for (direction_vectors) |vec| {
            const maybe_new_row = @as(isize, @intCast(row)) + vec[1];
            const maybe_new_col = @as(isize, @intCast(col)) + vec[0];

            if (!isInBounds(grid, maybe_new_row, maybe_new_col)) {
                continue;
            }

            const new_row = @as(usize, @intCast(maybe_new_row));
            const new_col = @as(usize, @intCast(maybe_new_col));

            if (grid[new_row][new_col] == plant_type and !visited_locations.contains(.{ .row = new_row, .col = new_col })) {
                try frontier.append(.{ .row = new_row, .col = new_col });
            }
        }
    }

    const perimeter: u32 = blk: {
        var sum: u32 = 0;
        var iter = edge_counts.valueIterator();
        while (iter.next()) |count| {
            if (count.* == 1) {
                sum += 1;
            }
        }
        break :blk sum;
    };

    return area * perimeter;
}

fn isInBounds(grid: [][]const u8, row: isize, col: isize) bool {
    return row >= 0 and row < grid.len and col >= 0 and col < grid[0].len;
}
