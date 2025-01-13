const std = @import("std");
const util = @import("util");

const ITERATIONS = 2000;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const lines = try util.readInputFileLines(u24, allocator, "day22.txt", parseLine);
    defer allocator.free(lines);

    var first_prices_by_seq_for_line = try allocator.alloc(std.AutoHashMap([4]i8, u4), lines.len);
    defer allocator.free(first_prices_by_seq_for_line);
    for (0..lines.len) |i| {
        first_prices_by_seq_for_line[i] = std.AutoHashMap([4]i8, u4).init(allocator);
    }
    defer {
        for (0..lines.len) |i| {
            first_prices_by_seq_for_line[i].deinit();
        }
    }

    // For each line: compute the price you would get after each sequence occurs for the first time
    {
        var prices = try allocator.alloc(u4, lines.len * ITERATIONS);
        defer allocator.free(prices);
        var price_diffs = try allocator.alloc(i8, lines.len * ITERATIONS);
        defer allocator.free(price_diffs);

        for (lines, 0..) |initial, i| {
            var secret = initial;

            for (0..ITERATIONS) |j| {
                const offset = i * ITERATIONS + j;

                var temp = secret << 6;
                secret ^= temp;
                secret &= 0xff_ffff;

                temp = secret >> 5;
                secret ^= temp;

                temp = secret << 11;
                secret ^= temp;
                secret &= 0xff_ffff;

                const price = @as(u4, @intCast(secret % 10));
                prices[offset] = price;
                if (j == 0) {
                    price_diffs[offset] = @as(i8, price) - @as(i8, @intCast(initial % 10));
                } else {
                    price_diffs[offset] = @as(i8, price) - @as(i8, @intCast(prices[offset - 1]));
                }

                if (j >= 3) {
                    const diff_seq = [4]i8{
                        price_diffs[offset - 3],
                        price_diffs[offset - 2],
                        price_diffs[offset - 1],
                        price_diffs[offset],
                    };
                    // Only store the price if this is the first time we've encountered the sequence,
                    // since the monkey would stop there
                    if (!first_prices_by_seq_for_line[i].contains(diff_seq)) {
                        try first_prices_by_seq_for_line[i].put(diff_seq, price);
                    }
                }
            }
        }
    }

    // Compute every possible sequence of price differences (about 50,000 possibilities)
    const diff_sequences = blk: {
        var array = std.ArrayList([4]i8).init(allocator);

        var iter = DiffSequenceIterator{};
        while (iter.next()) |seq| {
            try array.append(seq);
        }

        break :blk try array.toOwnedSlice();
    };
    defer allocator.free(diff_sequences);

    // For each possible sequence, add up all the bananas we would receive if
    // we stopped at it
    var most_bananas: usize = 0;
    for (diff_sequences) |diff_seq| {
        var bananas: usize = 0;
        for (0..lines.len) |i| {
            const first_price = first_prices_by_seq_for_line[i].get(diff_seq) orelse 0;
            bananas += first_price;
        }
        most_bananas = @max(most_bananas, bananas);
    }

    std.debug.print("{d}", .{most_bananas});
}

fn parseLine(_: std.mem.Allocator, line: []const u8) !u24 {
    return std.fmt.parseInt(u24, line, 10);
}

const DiffSequenceIterator = struct {
    state: [4]i8 = .{ -9, -9, -9, -9 },

    const Self = @This();

    fn next(self: *Self) ?[4]i8 {
        self.incState();
        if (self.state[0] > 9) {
            return null;
        }

        while (!isValid(self.state)) {
            self.incState();
            if (self.state[0] > 9) {
                return null;
            }
        }

        return self.state;
    }

    fn incState(self: *Self) void {
        self.state[3] += 1;
        if (self.state[3] < 10) {
            return;
        }

        self.state[3] = -9;
        self.state[2] += 1;
        if (self.state[2] < 10) {
            return;
        }

        self.state[2] = -9;
        self.state[1] += 1;
        if (self.state[1] < 10) {
            return;
        }

        self.state[1] = -9;
        self.state[0] += 1;
    }

    fn isValid(state: [4]i8) bool {
        var n: i8 = 9;
        n += state[0]; // 0..18
        n += state[1];
        if (n < 0 or n > 18) {
            return false;
        }
        n += state[2];
        if (n < 0 or n > 18) {
            return false;
        }
        n += state[3];
        if (n < 0 or n > 18) {
            return false;
        }
        return true;
    }
};
