const std = @import("std");
const util = @import("util");

const print = std.debug.print;

const Node = [2]u8;
const NodeSet = std.AutoHashMap(Node, void);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([2]Node, allocator, "day23.txt", parseLine);
    defer allocator.free(lines);

    var connections_by_node = std.AutoHashMap(Node, NodeSet).init(allocator);
    defer connections_by_node.deinit();
    defer {
        var iter = connections_by_node.valueIterator();
        while (iter.next()) |array| {
            array.deinit();
        }
    }

    for (lines) |line| {
        var result = try connections_by_node.getOrPut(line[0]);
        if (!result.found_existing) {
            result.value_ptr.* = NodeSet.init(allocator);
        }
        try result.value_ptr.put(line[1], {});

        result = try connections_by_node.getOrPut(line[1]);
        if (!result.found_existing) {
            result.value_ptr.* = NodeSet.init(allocator);
        }
        try result.value_ptr.put(line[0], {});
    }

    var maximum_clique = try findMaximumClique(allocator, &connections_by_node);
    defer maximum_clique.deinit();

    var clique_members = std.ArrayList(Node).init(allocator);
    defer clique_members.deinit();

    var clique_iter = maximum_clique.keyIterator();
    while (clique_iter.next()) |member_ptr| {
        try clique_members.append(member_ptr.*);
    }

    std.mem.sort([2]u8, clique_members.items, {}, nodeLessThan);
    for (clique_members.items) |member| {
        std.debug.print("{s},", .{member});
    }
}

fn parseLine(_: std.mem.Allocator, line: []const u8) ![2]Node {
    std.debug.assert(line.len == 5);
    return .{ .{ line[0], line[1] }, .{ line[3], line[4] } };
}

fn findMaximumClique(allocator: std.mem.Allocator, graph: *std.AutoHashMap(Node, NodeSet)) !NodeSet {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp_allocator = arena.allocator();

    var vertices = NodeSet.init(temp_allocator);
    var iter = graph.keyIterator();
    while (iter.next()) |node_ptr| {
        try vertices.put(node_ptr.*, {});
    }

    const current_clique = NodeSet.init(temp_allocator);
    const best_clique = NodeSet.init(temp_allocator);

    const result = try expandClique(temp_allocator, graph, &vertices, current_clique, best_clique);
    return result.cloneWithAllocator(allocator);
}

fn expandClique(
    allocator: std.mem.Allocator,
    graph: *std.AutoHashMap(Node, NodeSet),
    candidates: *NodeSet,
    current_clique: NodeSet,
    best_clique: NodeSet,
) !NodeSet {
    if (candidates.count() == 0) {
        return current_clique;
    }

    if (current_clique.count() + candidates.count() < best_clique.count()) {
        return current_clique;
    }

    var new_best_clique = best_clique;

    const v = do: {
        var temp = candidates.keyIterator();
        const node_ptr = temp.next().?;
        // Create a completely new array
        const node_copy = [2]u8{ node_ptr.*[0], node_ptr.*[1] };
        break :do node_copy;
    };
    _ = candidates.remove(v);

    var valid_candidates = do: {
        var temp = NodeSet.init(allocator);
        if (!graph.contains(v)) {
            std.debug.print("{s} not in graph?\n", .{&v});
            unreachable;
        }
        const neighbours = graph.get(v).?;
        var candidates_iter = candidates.keyIterator();
        while (candidates_iter.next()) |candidate_ptr| {
            if (neighbours.contains(candidate_ptr.*)) {
                try temp.put(candidate_ptr.*, {});
            }
        }
        break :do temp;
    };

    var clique_with_v = try current_clique.clone();
    try clique_with_v.put(v, {});
    var with_v = try expandClique(allocator, graph, &valid_candidates, clique_with_v, new_best_clique);
    if (with_v.count() > new_best_clique.count()) {
        new_best_clique = with_v;
    }

    var without_v = try expandClique(allocator, graph, candidates, current_clique, new_best_clique);
    if (without_v.count() > new_best_clique.count()) {
        new_best_clique = without_v;
    }

    try candidates.put(v, {});
    return new_best_clique;
}

fn nodeLessThan(_: void, lhs: Node, rhs: Node) bool {
    return std.mem.order(u8, &lhs, &rhs) == .lt;
}
