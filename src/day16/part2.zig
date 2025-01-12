const std = @import("std");
const util = @import("util");

const Direction = enum(u2) {
    east,
    south,
    west,
    north,
};

const TURNS = std.EnumMap(Direction, [2]Direction).init(.{
    .east = [2]Direction{ .north, .south },
    .south = [2]Direction{ .east, .west },
    .west = [2]Direction{ .south, .north },
    .north = [2]Direction{ .west, .east },
});

const MOVEMENT = std.EnumMap(Direction, [2]i8).init(.{
    .east = [2]i8{ 1, 0 },
    .south = [2]i8{ 0, 1 },
    .west = [2]i8{ -1, 0 },
    .north = [2]i8{ 0, -1 },
});

const DIRECTION_CHAR = std.EnumMap(Direction, u8).init(.{
    .east = '>',
    .south = 'v',
    .west = '<',
    .north = '^',
});

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const grid = try util.readInputFileLines([]u8, allocator, "day16.txt", parseLine);
    defer allocator.free(grid);
    defer {
        for (grid) |line| {
            allocator.free(line);
        }
    }

    var start_x: u16 = undefined;
    var start_y: u16 = undefined;
    var end_x: u16 = undefined;
    var end_y: u16 = undefined;

    for (grid, 0..) |row, y| {
        for (row, 0..) |char, x| {
            if (char == 'S') {
                start_x = @as(u16, @intCast(x));
                start_y = @as(u16, @intCast(y));
            }
            if (char == 'E') {
                end_x = @as(u16, @intCast(x));
                end_y = @as(u16, @intCast(y));
            }
        }
    }

    const search_config = SearchConfig.findPathConfig(grid, start_x, start_y, end_x, end_y);
    const paths = try util.findAllOptimalPaths(SearchConfig.Node, SearchConfig.Context, SearchConfig.Score, allocator, search_config);
    defer allocator.free(paths);
    defer {
        for (paths) |path| {
            allocator.free(path);
        }
    }

    if (paths.len == 0) {
        std.debug.print("no path :(", .{});
        return;
    }

    var coords_in_any_path = std.AutoHashMap([2]u16, void).init(allocator);
    defer coords_in_any_path.deinit();

    for (paths) |path| {
        for (path) |node| {
            try coords_in_any_path.put(.{ node.x, node.y }, {});
        }
    }

    std.debug.print("{d}\n\n", .{coords_in_any_path.count()});

    for (grid, 0..) |row, y| {
        for (row, 0..) |char, x| {
            if (coords_in_any_path.contains(.{ @as(u16, @intCast(x)), @as(u16, @intCast(y)) })) {
                std.debug.print("O", .{});
            } else {
                std.debug.print("{c}", .{char});
            }
        }
        std.debug.print("\n", .{});
    }
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

const SearchConfig = struct {
    const Node = struct {
        x: u16,
        y: u16,
        facing: Direction,
    };
    const Context = struct {
        grid: [][]u8,
        end_x: u16,
        end_y: u16,
    };
    const Score = u32;

    fn getDistance(context: *const Context, key: Node) Score {
        const x_dist = @as(i17, context.end_x) - @as(i17, key.x);
        const y_dist = @as(i17, context.end_y) - @as(i17, key.y);
        return @as(Score, @intCast(@abs(x_dist) + @abs(y_dist)));
    }

    fn getWeight(_: *const Context, from: Node, to: Node) Score {
        if (from.facing != to.facing) {
            std.debug.assert(from.x == to.x);
            std.debug.assert(from.y == to.y);
            return 1000;
        }

        std.debug.assert(from.facing == to.facing);
        return 1;
    }

    const max_neighbours = 3;

    fn getNeighbours(context: *const Context, key: Node, results: []?Node) void {
        const turns = TURNS.getAssertContains(key.facing);
        results[0] = .{ .x = key.x, .y = key.y, .facing = turns[0] };
        results[1] = .{ .x = key.x, .y = key.y, .facing = turns[1] };

        const move = MOVEMENT.getAssertContains(key.facing);
        const new_x = @as(u16, @intCast(@as(i17, key.x) + move[0]));
        const new_y = @as(u16, @intCast(@as(i17, key.y) + move[1]));

        if (context.grid[new_y][new_x] != '#') {
            results[2] = .{ .x = new_x, .y = new_y, .facing = key.facing };
        }
    }

    fn findPathConfig(grid: [][]u8, start_x: u16, start_y: u16, end_x: u16, end_y: u16) util.FindPathConfig(Node, Context, Score) {
        return .{
            .start = .{ .x = start_x, .y = start_y, .facing = .east },
            .max_neighbours = max_neighbours,
            .context = Context{ .grid = grid, .end_x = end_x, .end_y = end_y },
            .get_distance = getDistance,
            .get_weight = getWeight,
            .get_neighbours = getNeighbours,
        };
    }
};
