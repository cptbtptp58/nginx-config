require 'lib'
local cjson = require 'cjson'

local args = ngx.req.get_uri_args()
local arg_token = ngx.req.get_headers()["token"]

if arg_token ~= "mqhu9yxh5i2np7" then
    ngx.status = 403
    ngx.say("Forbidden: Invalid token")
    return ngx.exit(403)
end

ngx.header.content_type = "text/html"

ngx.say("current environment: " .. (cc_env_name or "unknown"))
ngx.say("<br>")
ngx.say("URI: " .. (ngx.var.uri or "unknown"))
ngx.say("<br>")
ngx.say("Arguments: " .. cjson.encode(args))
ngx.say("<br>")
ngx.say("Client IP: " .. (get_client_ip() or "unknown"))
ngx.say("<br>")
ngx.say("Client Domain: " .. (get_client_domain() or "unknown"))
ngx.say("<br>")
ngx.say("User Agent: " .. (get_user_agent() or "unknown"))
ngx.say("<br>")

ngx.say("<br><br>---统计---<br>")
local limit = ngx.shared.limit
local now_date = get_now_date()
local uv_key = now_date .. "_uv"
local pv_key = now_date .. "_pv"
ngx.say(string.format("今天的 UV: %s<br>", limit:get(uv_key) or "0"))
ngx.say(string.format("今天的 PV: %s<br>", limit:get(pv_key) or "0"))

ngx.exit(200)
