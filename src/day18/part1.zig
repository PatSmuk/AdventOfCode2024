const std = @import("std");
const util = @import("util");

const Coord = struct { x: u8, y: u8 };

const ALL_MOVES = [_][2]i8{
    .{ 1, 0 },
    .{ 0, 1 },
    .{ -1, 0 },
    .{ 0, -1 },
};

const GRID_SIZE = 71;
const BYTES_TO_SIMULATE = 1024;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const coords = try util.readInputFileLines(Coord, allocator, "day18.txt", parseLine);
    defer allocator.free(coords);
    std.debug.assert(coords.len >= BYTES_TO_SIMULATE);

    var corrupted = std.AutoHashMap(Coord, void).init(allocator);
    defer corrupted.deinit();

    for (0..BYTES_TO_SIMULATE) |i| {
        try corrupted.put(coords[i], {});
    }

    for (0..GRID_SIZE) |y| {
        for (0..GRID_SIZE) |x| {
            const coord = Coord{ .x = @as(u8, @intCast(x)), .y = @as(u8, @intCast(y)) };
            const char: u8 = if (corrupted.contains(coord)) '#' else '.';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});

    const search_config = SearchConfig.findPathConfig(&corrupted, .{ .x = GRID_SIZE - 1, .y = GRID_SIZE - 1 });
    const path = try util.findOnePath(SearchConfig.Node, SearchConfig.Context, SearchConfig.Score, allocator, search_config);
    defer allocator.free(path);

    if (path.len == 0) {
        std.debug.print("no path", .{});
        return;
    }

    var in_path = std.AutoHashMap(Coord, void).init(allocator);
    defer in_path.deinit();

    for (path) |coord| {
        try in_path.put(coord, {});
    }

    for (0..GRID_SIZE) |y| {
        for (0..GRID_SIZE) |x| {
            const coord = Coord{ .x = @as(u8, @intCast(x)), .y = @as(u8, @intCast(y)) };
            const char: u8 = if (corrupted.contains(coord)) '#' else if (in_path.contains(coord)) 'O' else '.';
            std.debug.print("{c}", .{char});
        }
        std.debug.print("\n", .{});
    }

    std.debug.print("\n{d}", .{path.len - 1});
}

fn parseLine(_: std.mem.Allocator, line: []const u8) !Coord {
    var iter = std.mem.tokenizeScalar(u8, line, ',');
    const x_str = iter.next().?;
    const y_str = iter.next().?;
    const x = try std.fmt.parseInt(u8, x_str, 10);
    const y = try std.fmt.parseInt(u8, y_str, 10);
    return .{ .x = x, .y = y };
}

const SearchConfig = struct {
    const Node = Coord;
    const Context = struct {
        corrupted: *const std.AutoHashMap(Coord, void),
        end: Coord,
    };
    const Score = u16;

    fn getDistance(context: *const Context, key: Node) Score {
        std.debug.assert(context.end.x >= key.x);
        std.debug.assert(context.end.y >= key.y);
        const x_dist = @as(i16, context.end.x) - @as(i16, key.x);
        const y_dist = @as(i16, context.end.y) - @as(i16, key.y);
        const dist = @as(Score, @intCast(@abs(x_dist) + @abs(y_dist)));
        return dist;
    }

    fn getNeighbours(context: *const Context, key: Node, results: []?Node) void {
        var results_i: usize = 0;

        for (0..ALL_MOVES.len) |i| {
            const x = @as(i8, @intCast(key.x)) + ALL_MOVES[i][0];
            const y = @as(i8, @intCast(key.y)) + ALL_MOVES[i][1];
            if (x < 0 or y < 0 or x > context.end.x or y > context.end.y) {
                continue;
            }
            const coord = Coord{ .x = @as(u8, @intCast(x)), .y = @as(u8, @intCast(y)) };
            if (context.corrupted.contains(coord)) {
                continue;
            }
            results[results_i] = coord;
            results_i += 1;
        }
    }

    fn findPathConfig(corrupted: *const std.AutoHashMap(Coord, void), end: Coord) util.FindPathConfig(Node, Context, Score) {
        return .{
            .start = .{ .x = 0, .y = 0 },
            .max_neighbours = ALL_MOVES.len,
            .context = Context{ .corrupted = corrupted, .end = end },
            .get_distance = getDistance,
            .get_neighbours = getNeighbours,
        };
    }
};
