use t::GRPC_CLI 'no_plan';

run_tests();

__DATA__

=== TEST 1: sanity
--- config
location /t {
    content_by_lua_block {
        local gcli = require("resty.grpc")
        assert(gcli.load("t/backend/proto/stream.proto"))

        local conn = assert(gcli.connect("127.0.0.1:50051"))
        local st, err = conn:new_client_stream("stream.ClientStream", "Recv", {data = "a"})
        if not st then
            ngx.say(err)
            return
        end
        st:close()
        ngx.say("ok")
    }
}
--- response_body
ok



=== TEST 2: stream closed by gc
--- config
location /t {
    content_by_lua_block {
        local gcli = require("resty.grpc")
        assert(gcli.load("t/backend/proto/stream.proto"))

        local conn = assert(gcli.connect("127.0.0.1:50051"))
        do
            local st, err = conn:new_client_stream("stream.ClientStream", "Recv", {data = "a"})
            if not st then
                ngx.say(err)
                return
            end
        end
        ngx.say("ok")
    }
}
--- response_body
ok



=== TEST 3: send & recv
--- config
location /t {
    content_by_lua_block {
        local gcli = require("resty.grpc")
        assert(gcli.load("t/backend/proto/stream.proto"))

        local conn = assert(gcli.connect("127.0.0.1:50051"))
        local st, err = conn:new_client_stream("stream.ClientStream", "Recv", {data = "a"})
        if not st then
            ngx.say(err)
            return
        end
        local data, err = st:recv_close()
        if not data then
            ngx.say(err)
            return
        end
        ngx.say(data.count)
        ngx.say(data.data)
    }
}
--- response_body
1
a



=== TEST 4: multi req & recv & close
--- config
location /t {
    content_by_lua_block {
        local gcli = require("resty.grpc")
        assert(gcli.load("t/backend/proto/stream.proto"))

        local conn = assert(gcli.connect("127.0.0.1:50051"))
        local st, err = conn:new_client_stream("stream.ClientStream", "Recv", {data = "a"})
        if not st then
            ngx.say(err)
            return
        end
        for i = 1, 4 do
            local ok, err = st:send({data = tostring(i)})
            if not ok then
                ngx.say(err)
                return
            end
        end
        local data, err = st:recv_close()
        if not data then
            ngx.say(err)
            return
        end
        ngx.say(data.count)
        ngx.say(data.data)
    }
}
--- response_body
5
a1234
