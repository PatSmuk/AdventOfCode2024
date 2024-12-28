const std = @import("std");
const util = @import("util");

const Location = struct { row: usize, col: usize };
const Edge = struct {
    start: Location,
    end: Location,
    topOrLeft: bool, // true for top and left edge, false otherwise
};

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
        try util.mapInc(Edge, u2, &edge_counts, .{ .start = .{ .row = row, .col = col }, .end = .{ .row = row, .col = col + 1 }, .topOrLeft = true }, 1);
        // 2
        try util.mapInc(Edge, u2, &edge_counts, .{ .start = .{ .row = row + 1, .col = col }, .end = .{ .row = row + 1, .col = col + 1 }, .topOrLeft = false }, 1);
        // 3
        try util.mapInc(Edge, u2, &edge_counts, .{ .start = .{ .row = row, .col = col }, .end = .{ .row = row + 1, .col = col }, .topOrLeft = true }, 1);
        // 4
        try util.mapInc(Edge, u2, &edge_counts, .{ .start = .{ .row = row, .col = col + 1 }, .end = .{ .row = row + 1, .col = col + 1 }, .topOrLeft = false }, 1);

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

    var edges = std.ArrayList(Edge).init(allocator);
    defer edges.deinit();

    var iter = edge_counts.iterator();
    while (iter.next()) |entry| {
        var edge = entry.key_ptr.*;
        edge.topOrLeft = !edge.topOrLeft;
        if (!edge_counts.contains(edge)) {
            try edges.append(entry.key_ptr.*);
        }
    }

    const edge_count = try mergeEdges(allocator, edges.items);
    return area * edge_count;
}

fn isInBounds(grid: [][]const u8, row: isize, col: isize) bool {
    return row >= 0 and row < grid.len and col >= 0 and col < grid[0].len;
}

fn mergeEdges(allocator: std.mem.Allocator, edges: []Edge) !u32 {
    var merged_edges = std.ArrayList(Edge).init(allocator);
    defer merged_edges.deinit();

    for (edges) |edge| {
        var first_merge_i: ?usize = null;

        // Look for a potential partner to merge edge into
        loop: for (merged_edges.items, 0..) |potential_partner, i| {
            // Top edges only merge with top edges, bottom with bottom, etc.
            if (edge.topOrLeft != potential_partner.topOrLeft) {
                continue;
            }

            // | pp |edge|(fm)|
            if (edge.start.row == potential_partner.end.row and edge.start.col == potential_partner.end.col and (edge.end.row == potential_partner.start.row or edge.end.col == potential_partner.start.col)) {
                if (first_merge_i == null) {
                    // Update pp's end to edge's end
                    merged_edges.items[i].end = edge.end;
                    first_merge_i = i;
                } else {
                    // edge is between two edges, set start of fm to start of pp and remove pp
                    merged_edges.items[first_merge_i.?].start = potential_partner.start;
                    _ = merged_edges.swapRemove(i);
                    break :loop;
                }
            } else if (edge.end.row == potential_partner.start.row and edge.end.col == potential_partner.start.col and (edge.start.row == potential_partner.end.row or edge.start.col == potential_partner.end.col)) {
                // |(fm)|edge| pp |
                if (first_merge_i == null) {
                    // Update pp's start to edge's start
                    merged_edges.items[i].start = edge.start;
                    first_merge_i = i;
                } else {
                    // edge is between two edges, set end of fm to end of pp and remove pp
                    merged_edges.items[first_merge_i.?].end = potential_partner.end;
                    _ = merged_edges.swapRemove(i);
                    break :loop;
                }
            }
        }

        // If we did not merge with anything and consume edge, add edge as a potential merge target
        if (first_merge_i == null) {
            try merged_edges.append(edge);
        }
    }

    return @as(u32, @intCast(merged_edges.items.len));
}
