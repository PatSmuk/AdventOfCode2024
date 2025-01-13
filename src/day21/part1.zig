const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines([]u8, allocator, "day21.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

const SearchConfig = struct {
    const Node = struct {
        last_key_pressed: ?u8,
        first_robot_position: u8,
        second_robot_position: u8,
        third_robot_position: u8,
        code_entered: []const u8,
    };
    const Context = []const u8;
    const Score = usize;

    fn getDistance(context: *const Context, node: Node) Score {
        const remaining_presses = context.len - node.code_entered.len;
        if (remaining_presses == 0) {
            return 0;
        }

        var score = remaining_presses;

        score *= 5;
        const dist = finalKeypadDistance(node.third_robot_position, context[context.len - remaining_presses]);
        score += @as(usize, @intCast(@abs(dist[0]) + @abs(dist[1])));

        return score;
    }

    fn getNeighbours(context: *const Context, node: Node, results: []?Node) void {
        _ = results; // autofix
        _ = node; // autofix
        _ = context; // autofix

    }

    fn findPathConfig(door_code: []const u8) util.FindPathConfig(Node, Context, Score) {
        return .{
            .start = .{
                .last_key_pressed = null,
            },
            .max_neighbours = 5,
            .context = door_code,
            .get_distance = getDistance,
            .get_neighbours = getNeighbours,
        };
    }
};

fn finalKeypadDistance(current: u8, target: u8) [2]i8 {
    const current_pos = finalKeypadPosition(current);
    const target_pos = finalKeypadPosition(target);

    return .{ target_pos[0] - current_pos[0], target_pos[1] - current_pos[1] };
}

fn finalKeypadPosition(key: u8) [2]i8 {
    switch (key) {
        '7' => return .{ 0, 0 },
        '8' => return .{ 1, 0 },
        '9' => return .{ 2, 0 },
        '4' => return .{ 0, 1 },
        '5' => return .{ 1, 1 },
        '6' => return .{ 2, 1 },
        '1' => return .{ 0, 2 },
        '2' => return .{ 1, 2 },
        '3' => return .{ 2, 2 },
        '0' => return .{ 1, 3 },
        'A' => return .{ 2, 3 },
        else => unreachable,
    }
}

fn directionalKeypadDistance(current: u8, target: u8) [2]i8 {
    const current_pos = directionalKeypadPosition(current);
    const target_pos = directionalKeypadPosition(target);

    return .{ target_pos[0] - current_pos[0], target_pos[1] - current_pos[1] };
}

fn directionalKeypadPosition(key: u8) [2]i8 {
    switch (key) {
        '^' => return .{ 1, 0 },
        'A' => return .{ 2, 0 },
        '<' => return .{ 0, 1 },
        'V' => return .{ 1, 1 },
        '>' => return .{ 2, 1 },
        else => unreachable,
    }
}

fn getTargetDirectionKey(dist: [2]i8) u8 {
    if (dist[0] == 0) {
        if (dist[1] < 0) {
            return '^';
        } else if (dist[1] > 0) {
            return 'V';
        } else {
            return 'A';
        }
    }
    if (dist[1] == 0) {}
}
