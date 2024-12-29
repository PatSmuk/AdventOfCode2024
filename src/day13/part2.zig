const std = @import("std");
const util = @import("util");
const Regex = @import("regex").Regex;

const Button = struct {
    x: u64,
    y: u64,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var button_regex = try Regex.compile(allocator, "Button (A|B): X\\+(\\d+), Y\\+(\\d+)");
    defer button_regex.deinit();
    var prize_regex = try Regex.compile(allocator, "Prize: X=(\\d+), Y=(\\d+)");
    defer prize_regex.deinit();

    const lines = try util.readInputFileLines([]u8, allocator, "day13.txt", parseLine);
    defer allocator.free(lines);
    defer {
        for (lines) |line| {
            allocator.free(line);
        }
    }

    var a_button = Button{ .x = 0, .y = 0 };
    var b_button = Button{ .x = 0, .y = 0 };

    var total_tokens: u64 = 0;

    for (lines) |line| {
        if (line.len == 0) {
            continue;
        }

        var maybe_captures = try button_regex.captures(line);
        if (maybe_captures) |*captures| {
            defer captures.deinit();

            const letter = captures.sliceAt(1).?;
            const x_str = captures.sliceAt(2).?;
            const y_str = captures.sliceAt(3).?;
            const x = try std.fmt.parseInt(u64, x_str, 10);
            const y = try std.fmt.parseInt(u64, y_str, 10);

            if (letter[0] == 'A') {
                a_button.x = x;
                a_button.y = y;
            } else {
                b_button.x = x;
                b_button.y = y;
            }
        } else {
            var captures = (try prize_regex.captures(line)).?;
            defer captures.deinit();

            const x_str = captures.sliceAt(1).?;
            const y_str = captures.sliceAt(2).?;
            const x = try std.fmt.parseInt(u64, x_str, 10);
            const y = try std.fmt.parseInt(u64, y_str, 10);

            if (lowestPriceToWin(x + 10000000000000, y + 10000000000000, a_button, b_button)) |price| {
                total_tokens += price;
            }
        }
    }

    std.debug.print("{d}", .{total_tokens});
}

fn parseLine(allocator: std.mem.Allocator, line: []const u8) ![]u8 {
    return allocator.dupe(u8, line);
}

fn lowestPriceToWin(prize_x: u64, prize_y: u64, a_button: Button, b_button: Button) ?u64 {
    var a_button_copy = a_button;
    var prize_x_copy = prize_x;
    var prize_y_copy = prize_y;

    // Multiply so there's a common denominator for terms of both equations
    // (b_button.y*b_button.x is the common denominator)
    // Don't bother with B since it will be going away once we subtract
    a_button_copy.x *= b_button.y;
    prize_x_copy *= b_button.y;

    a_button_copy.y *= b_button.x;
    prize_y_copy *= b_button.x;

    // Subtract the two equations to remove B and isolate A
    var a = diff(a_button_copy.x, a_button_copy.y);
    const target = diff(prize_x_copy, prize_y_copy);

    // If target == 0 then there are infinitely-many solutions
    std.debug.assert(target != 0);

    // If target is not cleanly divisible by A then there is no solution
    if (target % a != 0) {
        return null;
    }

    a = target / a;

    // Same with B
    if ((prize_x - a * a_button.x) % b_button.x != 0) {
        return null;
    }
    const b = (prize_x - a * a_button.x) / b_button.x;

    return a * 3 + b;
}

/// Always positive difference between two u64
fn diff(a: u64, b: u64) u64 {
    if (a > b) {
        return a - b;
    }
    return b - a;
}
