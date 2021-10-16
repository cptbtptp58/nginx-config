
local cjson=require 'cjson'
local geo=require 'resty.maxminddb'

local args = ngx.req.get_uri_args()
local client_ip = args["ip"]

local headers = ngx.req.get_headers()
local arg_token = headers["token"]

if arg_token ~= "mqhu9yxh5i2np7" then
    ngx.exit(403)
end

ngx.say("current environtment: "..cc_env_name)
ngx.say("<br>")
ngx.say(ngx.var.uri)
ngx.say(cjson.encode(args))
ngx.say("<br>")

if not client_ip or client_ip == "" then
    client_ip=get_client_ip()
end
ngx.say("<br>X_Forwarded_For:<br>")
ngx.say(ngx.req.get_headers()["X_Forwarded_For"])
ngx.say("<br>X_real_ip:<br>")
ngx.say(ngx.req.get_headers()["X_real_ip"])
ngx.say("<br>remote_addr:<br>")
ngx.say(ngx.var.remote_addr)
ngx.say("<br>get_client_ip():<br>")
ngx.say(client_ip)
ngx.say("<br><br>")

init_geo_data()
local res,err=geo.lookup(client_ip)
ngx.say(cjson.encode(res))
ngx.say("<br>")

local check_code = rewrite_check(client_ip)
ngx.say(string.format("<br>%s 的跳转验证结果: %s", client_ip, check_code))

ngx.say("<br><br>---验证码对照表---<br>")
ngx.say("0: 可跳转<br>")
ngx.say("10: 未打开开关<br>")
ngx.say(string.format("20: 不在设定时间段(%s)(%s)<br>", 
    cc_redirect_period_hour, cc_redirect_period_minute))
ngx.say(string.format("30: 超过最大跳转次数(%s)<br>", cc_redirect_limit))
ngx.say("40: ip已经跳转过<br>")
ngx.say(string.format("50: 上个ip跳转后还没超过%s秒<br>", cc_redirect_expire_time_another_ip))
ngx.say("10x: ip不在服务区<br>")
ngx.say("--100: ip无法解析<br>")
ngx.say("--101: 地区未解析出来<br>")
ngx.say("--102: 国家不支持<br>")
ngx.say("--103: 地区不支持<br>")

ngx.say("<br><br>---统计---<br>")
local limit = ngx.shared.limit
local now_table = os.date("*t", os.time())
local now_date = table.concat({now_table["year"], now_table["month"], now_table["day"]})
ngx.say(string.format("今天多少ip跳转过: %s<br>", limit:get(now_date))) 
ngx.say(string.format("%s 是否跳转过: %s<br>", client_ip, limit:get(client_ip)))

ngx.exit(200)
