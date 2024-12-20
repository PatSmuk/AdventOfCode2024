const std = @import("std");
const util = @import("util");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const ordersAndLists = try util.readInputFileLines(OrderOrList, allocator, "day05.txt", parseLine);
    defer allocator.free(ordersAndLists);
    defer {
        for (ordersAndLists) |orderOrList| {
            switch (orderOrList) {
                .list => |list| allocator.free(list),
                else => {},
            }
        }
    }

    // Map from a page number to the set of all pages numbers that must come before it
    var pages_that_must_come_before = std.AutoHashMap(u8, std.AutoHashMap(u8, void)).init(allocator);
    defer pages_that_must_come_before.deinit();
    defer {
        var iter = pages_that_must_come_before.valueIterator();
        while (iter.next()) |page_set| {
            page_set.deinit();
        }
    }

    var middle_sum: usize = 0;

    for (ordersAndLists) |orderOrList| {
        switch (orderOrList) {
            .order => |order| {
                const maybe_pages = pages_that_must_come_before.getPtr(order.second);
                if (maybe_pages != null) {
                    try maybe_pages.?.put(order.first, {});
                } else {
                    var pages = std.AutoHashMap(u8, void).init(allocator);
                    try pages.put(order.first, {});
                    try pages_that_must_come_before.put(order.second, pages);
                }
            },
            .list => |list| {
                // Make a copy of the list and then sort it
                const sorted_list = try allocator.dupe(u8, list);
                defer allocator.free(sorted_list);

                const ctx = ComparePagesContext{ .pages_that_must_come_before = &pages_that_must_come_before };
                std.mem.sortUnstable(u8, sorted_list, ctx, comparePages);

                // If sorted and unsorted are not equal then something changed,
                // therefore the original order was not valid
                if (!std.mem.eql(u8, list, sorted_list)) {
                    const middle = sorted_list[sorted_list.len / 2];
                    middle_sum += middle;
                }
            },
        }
    }

    std.debug.print("{d}\n", .{middle_sum});
}

const OrderOrListTag = enum { order, list };

const OrderOrList = union(OrderOrListTag) {
    order: struct { first: u8, second: u8 },
    list: []u8,
};

fn parseLine(allocator: std.mem.Allocator, line: []const u8) !OrderOrList {
    // XX|YY
    if (std.mem.containsAtLeast(u8, line, 1, "|")) {
        var iter = std.mem.tokenizeScalar(u8, line, '|');
        const first = try std.fmt.parseInt(u8, iter.next().?, 10);
        const second = try std.fmt.parseInt(u8, iter.next().?, 10);
        return .{ .order = .{ .first = first, .second = second } };
    }

    // XX,YY,ZZ
    var iter = std.mem.tokenizeScalar(u8, line, ',');

    var nums = std.ArrayList(u8).init(allocator);
    defer nums.deinit();

    while (iter.next()) |num_string| {
        const num = try std.fmt.parseInt(u8, num_string, 10);
        try nums.append(num);
    }

    return .{ .list = try allocator.dupe(u8, nums.items) };
}

const ComparePagesContext = struct {
    pages_that_must_come_before: *std.AutoHashMap(u8, std.AutoHashMap(u8, void)),
};

// Returns true if lhs page must come before rhs, otherwise false
fn comparePages(ctx: ComparePagesContext, lhs: u8, rhs: u8) bool {
    const pages_before_rhs = ctx.pages_that_must_come_before.get(rhs);
    if (pages_before_rhs != null and pages_before_rhs.?.contains(lhs)) {
        // lhs comes before rhs, so lhs is less than rhs
        return true;
    }
    // lhs does not come before rhs, so rhs must be less than lhs
    return false;
}
