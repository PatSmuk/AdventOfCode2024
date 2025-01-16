const std = @import("std");
const util = @import("util");

const print = std.debug.print;

const Node = [2]u8;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([2]Node, allocator, "day23.txt", parseLine);
    defer allocator.free(lines);

    var connections_by_node = std.AutoHashMap(Node, std.AutoHashMap(Node, void)).init(allocator);
    defer connections_by_node.deinit();
    defer {
        var iter = connections_by_node.valueIterator();
        while (iter.next()) |array| {
            array.deinit();
        }
    }

    var start_with_t = std.AutoHashMap(Node, void).init(allocator);
    defer start_with_t.deinit();

    for (lines) |line| {
        var result = try connections_by_node.getOrPut(line[0]);
        if (!result.found_existing) {
            result.value_ptr.* = std.AutoHashMap(Node, void).init(allocator);
        }
        try result.value_ptr.put(line[1], {});

        result = try connections_by_node.getOrPut(line[1]);
        if (!result.found_existing) {
            result.value_ptr.* = std.AutoHashMap(Node, void).init(allocator);
        }
        try result.value_ptr.put(line[0], {});

        if (line[0][0] == 't') {
            try start_with_t.put(line[0], {});
        }
        if (line[1][0] == 't') {
            try start_with_t.put(line[1], {});
        }
    }

    var matching_sets = std.AutoHashMap([3]Node, void).init(allocator);
    defer matching_sets.deinit();

    var iter = start_with_t.keyIterator();
    while (iter.next()) |key| {
        const connection_set = connections_by_node.get(key.*).?;
        if (connection_set.count() < 2) {
            continue;
        }

        var connections = blk: {
            var temp = std.ArrayList(Node).init(allocator);
            var connected_iter = connection_set.keyIterator();
            while (connected_iter.next()) |other| {
                try temp.append(other.*);
            }
            break :blk temp;
        };
        defer connections.deinit();

        for (0..connections.items.len - 1) |i| {
            for (i..connections.items.len) |j| {
                const first = connections.items[i];
                const second = connections.items[j];

                if (connections_by_node.get(first).?.contains(second)) {
                    var set = [3]Node{ key.*, first, second };
                    std.mem.sort(Node, &set, {}, compareNodes);
                    try matching_sets.put(set, {});
                }
            }
        }
    }

    var matching_iter = matching_sets.keyIterator();
    while (matching_iter.next()) |set| {
        print("{s} {s} {s}\n", .{ set[0], set[1], set[2] });
    }
    print("{d}", .{matching_sets.count()});
}

fn parseLine(_: std.mem.Allocator, line: []const u8) ![2]Node {
    std.debug.assert(line.len == 5);
    return .{ .{ line[0], line[1] }, .{ line[3], line[4] } };
}

fn compareNodes(_: void, lhs: Node, rhs: Node) bool {
    return std.mem.order(u8, &lhs, &rhs) == .lt;
}
