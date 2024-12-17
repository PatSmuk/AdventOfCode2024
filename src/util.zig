const std = @import("std");

/// Reads lines from `inputs/${inputFileName}`, then passes each line to `parseLine`
/// and returns a slice of the return values.
///
/// The caller owns the slice of results and must free it.
///
/// The slices passed to `parseLine` *do not live beyond the end of `readInputFileLines`*
/// and must be copied if you want to use them after `readInputFileLines` is finished.
pub fn readInputFileLines(
    comptime ParserResult: type,
    allocator: std.mem.Allocator,
    inputFileName: []const u8,
    parseLine: *const fn (allocator: std.mem.Allocator, line: []const u8) anyerror!ParserResult,
) ![]ParserResult {
    // Get directory of running program executable
    const exe_path = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_path);

    const exe_dir = std.fs.path.dirname(exe_path) orelse ".";

    // Now use that to get the input file's path
    const file_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_dir, "..", "inputs", inputFileName });
    defer allocator.free(file_path);

    // Open the input file
    const file = try std.fs.openFileAbsolute(file_path, .{});
    defer file.close();

    // Read the entire contents
    const file_contents = try file.readToEndAlloc(allocator, 1024 * 1024 * 16);
    defer allocator.free(file_contents);

    var lines_iterator = std.mem.tokenizeAny(u8, file_contents, "\n\r");

    // Collect the parsed lines in an ArrayList
    var parsed_lines = std.ArrayList(ParserResult).init(allocator);
    defer parsed_lines.deinit();

    while (lines_iterator.next()) |line| {
        try parsed_lines.append(try parseLine(allocator, line));
    }

    // Return the results as a slice, dupe because parsed_lines will deinit
    return allocator.dupe(ParserResult, parsed_lines.items);
}
