const std = @import("std");
const c = @cImport({
    @cInclude("webserver.h");
});

// Sentinel-terminated C strings for HTTP reason and content-type
const OK: [:0]const u8 = &[_:0]u8{ 'O','K' };
const ISE: [:0]const u8 = &[_:0]u8{ 'I','n','t','e','r','n','a','l',' ','S','e','r','v','e','r',' ','E','r','r','o','r' };
const TEXT_PLAIN_UTF8: [:0]const u8 = &[_:0]u8{
    't','e','x','t','/','p','l','a','i','n',';',' ',
    'c','h','a','r','s','e','t','=','u','t','f','-','8'
};
const GET: [:0]const u8 = &[_:0]u8{ 'G','E','T' };
const ROOT: [:0]const u8 = &[_:0]u8{ '/' };
const HEALTH_PATH: [:0]const u8 = &[_:0]u8{ '/','h','e','a','l','t','h' };
const METRICS_PATH: [:0]const u8 = &[_:0]u8{ '/','m','e','t','r','i','c','s' };

export fn hello_handler(req: [*c]const c.ws_request, user: ?*anyopaque) callconv(.c) c_int {
    _ = user;
    const body = "Hello from Zig\n";
    // reason and content_type must be C-strings
    return @as(c_int, @intCast(c.ws_send_response(req, 200, OK, TEXT_PLAIN_UTF8, body.ptr, body.len)));
}

export fn health_handler(req: [*c]const c.ws_request, user: ?*anyopaque) callconv(.c) c_int {
    _ = user;
    const body = "OK\n";
    return @as(c_int, @intCast(c.ws_send_response(req, 200, OK, TEXT_PLAIN_UTF8, body.ptr, body.len)));
}

export fn metrics_handler(req: [*c]const c.ws_request, user: ?*anyopaque) callconv(.c) c_int {
    _ = user;
    if (req == null or req.*.server == null) {
        const body = "metrics unavailable\n";
        return @as(c_int, @intCast(c.ws_send_response(req, 500, ISE, TEXT_PLAIN_UTF8, body.ptr, body.len)));
    }
    var m: c.ws_metrics = undefined;
    if (c.ws_server_get_metrics(req.*.server, &m) != 0) {
        const body = "metrics error\n";
        return @as(c_int, @intCast(c.ws_send_response(req, 500, ISE, TEXT_PLAIN_UTF8, body.ptr, body.len)));
    }
    var buf: [512]u8 = undefined;
    const bodySlice = std.fmt.bufPrint(
        &buf,
        \\accepted: {d}
        \\enqueued: {d}
        \\dequeued: {d}
        \\dropped_new: {d}
        \\dropped_oldest: {d}
        \\bytes_sent: {d}
        \\resp_2xx: {d}
        \\resp_3xx: {d}
        \\resp_4xx: {d}
        \\resp_5xx: {d}
        \\queue_len: {d}
        \\queue_peak: {d}
        \\threads: {d}
        \\
        ,
        .{
            m.accepted, m.enqueued, m.dequeued,
            m.dropped_new, m.dropped_oldest, m.bytes_sent,
            m.responses_2xx, m.responses_3xx, m.responses_4xx, m.responses_5xx,
            m.queue_len, m.queue_max_observed, m.nthreads,
        },
    ) catch {
        const body = "format error\n";
        return @as(c_int, @intCast(c.ws_send_response(req, 500, ISE, TEXT_PLAIN_UTF8, body.ptr, body.len)));
    };
    return @as(c_int, @intCast(c.ws_send_response(req, 200, OK, TEXT_PLAIN_UTF8, bodySlice.ptr, bodySlice.len)));
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
    if (c.ws_server_add_route(srv, GET, ROOT, hello_handler, null) != 0) {
        std.debug.print("zig-demo: failed to add route /\n", .{});
        c.ws_server_free(srv);
        return error.Unexpected;
    }
    if (c.ws_server_add_route(srv, GET, HEALTH_PATH, health_handler, null) != 0) {
        std.debug.print("zig-demo: failed to add route /health\n", .{});
        c.ws_server_free(srv);
        return error.Unexpected;
    }
    if (c.ws_server_add_route(srv, GET, METRICS_PATH, metrics_handler, null) != 0) {
        std.debug.print("zig-demo: failed to add route /metrics\n", .{});
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
