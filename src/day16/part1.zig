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

    var start_x: u15 = undefined;
    var start_y: u15 = undefined;
    var end_x: u15 = undefined;
    var end_y: u15 = undefined;

    for (grid, 0..) |row, y| {
        for (row, 0..) |char, x| {
            if (char == 'S') {
                start_x = @as(u15, @intCast(x));
                start_y = @as(u15, @intCast(y));
            }
            if (char == 'E') {
                end_x = @as(u15, @intCast(x));
                end_y = @as(u15, @intCast(y));
            }
        }
    }

    const search_config = SearchConfig.aStarConfig(grid, start_x, start_y, end_x, end_y);
    const paths = try util.aStarSearch(u32, SearchConfig.Context, u32, allocator, search_config);
    defer allocator.free(paths);
    defer {
        for (paths) |path| {
            allocator.free(path);
        }
    }

    var total_cost: u32 = 0;
    if (paths.len == 0) {
        std.debug.print("no path :(", .{});
        return;
    }
    const path = paths[0];

    for (0..path.len - 1) |i| {
        const start = path[i];
        const end = path[i + 1];

        var x: u15 = undefined;
        var y: u15 = undefined;
        var start_facing: Direction = undefined;
        SearchConfig.fromNode(start, &x, &y, &start_facing);

        var end_facing: Direction = undefined;
        SearchConfig.fromNode(end, &x, &y, &end_facing);

        if (start_facing != end_facing) {
            total_cost += 1000;
        } else {
            total_cost += 1;
        }
    }
    std.debug.print("{d}\n\n", .{total_cost});

    for (grid, 0..) |row, y| {
        for (row, 0..) |char, x| {
            for (path) |node| {
                var path_x: u15 = undefined;
                var path_y: u15 = undefined;
                var facing: Direction = undefined;
                SearchConfig.fromNode(node, &path_x, &path_y, &facing);

                if (path_x == x and path_y == y) {
                    std.debug.print("{c}", .{DIRECTION_CHAR.getAssertContains(facing)});
                    break;
                }
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
    const Node = u32;
    const Score = u32;
    const Context = struct {
        grid: [][]u8,
        end_x: u15,
        end_y: u15,
    };

    fn toNode(x: u15, y: u15, facing: Direction) Node {
        return (@as(u32, x) << 17) | (@as(u32, y) << 2) | @intFromEnum(facing);
    }

    fn fromNode(key: Node, x: *u15, y: *u15, facing: *Direction) void {
        x.* = @as(u15, @intCast(key >> 17));
        y.* = @as(u15, @intCast(key >> 2 & 0x7fff));
        facing.* = @enumFromInt(key & 0b11);
    }

    fn getDistance(context: *const Context, key: Node) Score {
        var x: u15 = undefined;
        var y: u15 = undefined;
        var facing: Direction = undefined;
        fromNode(key, &x, &y, &facing);

        const x_dist = @as(i16, context.end_x) - @as(i16, x);
        const y_dist = @as(i16, context.end_y) - @as(i16, y);
        return @as(Node, @intCast(@abs(x_dist) + @abs(y_dist)));
    }

    fn getWeight(_: *const Context, from: Node, to: Node) Score {
        var from_x: u15 = undefined;
        var from_y: u15 = undefined;
        var from_facing: Direction = undefined;
        fromNode(from, &from_x, &from_y, &from_facing);

        var to_x: u15 = undefined;
        var to_y: u15 = undefined;
        var to_facing: Direction = undefined;
        fromNode(to, &to_x, &to_y, &to_facing);

        if (from_facing != to_facing) {
            std.debug.assert(from_x == to_x);
            std.debug.assert(from_y == to_y);
            return 1000;
        }

        std.debug.assert(from_facing == to_facing);
        return 1;
    }

    fn getNeighbours(context: *const Context, key: Node, results: []?Node) void {
        var x: u15 = undefined;
        var y: u15 = undefined;
        var facing: Direction = undefined;
        fromNode(key, &x, &y, &facing);

        const turns = TURNS.getAssertContains(facing);
        results[0] = toNode(x, y, turns[0]);
        results[1] = toNode(x, y, turns[1]);

        const move = MOVEMENT.getAssertContains(facing);
        const new_x = @as(u15, @intCast(@as(i16, x) + move[0]));
        const new_y = @as(u15, @intCast(@as(i16, y) + move[1]));

        if (context.grid[new_y][new_x] != '#') {
            results[2] = toNode(new_x, new_y, facing);
        }
    }

    fn aStarConfig(grid: [][]u8, start_x: u15, start_y: u15, end_x: u15, end_y: u15) util.AStarConfig(Node, Context, Score) {
        return .{
            .start = toNode(start_x, start_y, .east),
            .max_neighbours = 3,
            .context = Context{ .grid = grid, .end_x = end_x, .end_y = end_y },
            .get_distance = getDistance,
            .get_weight = getWeight,
            .get_neighbours = getNeighbours,
        };
    }
};
