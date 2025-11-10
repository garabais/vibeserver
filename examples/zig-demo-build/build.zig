const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // Use default target/optimize; override via `zig build -Dtarget=... -Doptimize=...` if desired.

    // Include paths to the C library headers (public and private)
    exe.addIncludePath(b.path("../../lib/webserver/include"));
    exe.addIncludePath(b.path("../../lib/webserver/src"));

    // Compile C sources directly (discover all .c files under lib/webserver/src)
    var c_files = std.ArrayListUnmanaged([]const u8){};
    defer c_files.deinit(b.allocator);

    var dir = std.fs.cwd().openDir("../../lib/webserver/src", .{ .iterate = true }) catch |e| {
        std.log.err("openDir ../../lib/webserver/src failed: {s}", .{@errorName(e)});
        @panic("openDir failed");
    };
    defer dir.close();

    var walker = dir.walk(b.allocator) catch |e| {
        std.log.err("walk failed: {s}", .{@errorName(e)});
        @panic("walk failed");
    };
    defer walker.deinit();

    while (true) {
        const ent = walker.next() catch |e| {
            std.log.err("walk next failed: {s}", .{@errorName(e)});
            @panic("walk next failed");
        } orelse break;

        if (ent.kind == .file and std.mem.endsWith(u8, ent.path, ".c")) {
            const full_path = b.pathJoin(&.{ "../../lib/webserver/src", ent.path });
            (c_files.append(b.allocator, full_path) catch |e| {
                std.log.err("append failed: {s}", .{@errorName(e)});
                @panic("append failed");
            });
        }
    }

    exe.addCSourceFiles(.{
        .files = c_files.items,
        .flags = &.{
            "-std=c11",
            "-D_POSIX_C_SOURCE=200809L",
            "-pthread",
        },
    });

    // Link libc and pthread
    exe.linkLibC();
    exe.linkSystemLibrary("pthread");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the zig demo");
    run_step.dependOn(&run_cmd.step);
}
