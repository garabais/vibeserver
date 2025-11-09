const std = @import("std");
const c = @cImport({
    @cInclude("webserver.h");
});

export fn hello_handler(req: [*]const c.ws_request, user: ?*anyopaque) callconv(.C) c_int {
    _ = user;
    const body = "Hello from Zig\n";
    // reason and content_type must be C-strings
    return @intCast(c_int, c.ws_send_response(req, 200, c"OK", c"text/plain; charset=utf-8", body, body.len));
}

pub fn main() !void {
    // Configure server options (use library defaults where 0)
    var opts: c.ws_server_opts = std.mem.zeroes(c.ws_server_opts);
    opts.port = 8082;
    opts.nthreads = 0; // default (cores, at least 2)
    opts.queue_capacity = 0; // default 1024
    opts.backlog = 0; // default SOMAXCONN
    opts.enable_keepalive = 1;
    opts.keepalive_timeout_ms = 15000;
    opts.max_keepalive_requests = 100;
    opts.log_fn = null; // use default stderr logger
    opts.log_user = null;
    opts.log_level = c.WS_LOG_INFO;
    opts.log_format = null;
    opts.log_to_stderr = 1;
    opts.queue_policy = c.WS_QUEUE_BLOCK;

    const srv = c.ws_server_new_with_opts(&opts);
    if (srv == null) {
        std.debug.print("zig-demo: failed to create server\n", .{});
        return error.Unexpected;
    }

    // Register simple routes
    if (c.ws_server_add_route(srv, c"GET", c"/", hello_handler, null) != 0) {
        std.debug.print("zig-demo: failed to add route /\n", .{});
        c.ws_server_free(srv);
        return error.Unexpected;
    }
    if (c.ws_server_add_route(srv, c"GET", c"/health", hello_handler, null) != 0) {
        std.debug.print("zig-demo: failed to add route /health\n", .{});
        c.ws_server_free(srv);
        return error.Unexpected;
    }

    const rc = c.ws_server_run(srv);
    c.ws_server_free(srv);
    if (rc != 0) {
        std.debug.print("zig-demo: server run returned error {d}\n", .{rc});
        return error.Unexpected;
    }
}
