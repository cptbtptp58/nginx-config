local cjson=require 'cjson'
local geo=require 'resty.maxminddb'

function get_now_date()
    local now_table = os.date("*t", os.time())
    local now_date = table.concat({now_table["year"], now_table["month"], now_table["day"]})
    return now_date
end

function init_geo_data()
    if not geo.initted() then
        geo.init("/usr/local/openresty/geo/GeoLite2-City.mmdb")
    end
end

--is ip usable to redirect
function check_ip_service_area(ip)
    -- 初始化数据
    init_geo_data()
    local res, err=geo.lookup(ip)
    if not res then
        return 100
    end

    local country = res["country"]
    local subdivisions = res["subdivisions"]
    if not country or not subdivisions or length(subdivisions[1])==0 then
        return 101
    end

    -- verify the country
    local countries_allowed = split(cc_redirect_countries_allowed, "-") 
    local country_code = country["iso_code"]
    if not is_in_list(country_code, countries_allowed) then
        return 102
    end
    
    -- verify the province
    local provinces_allowed = split(cc_redirect_provinces_allowed, "-")
    local province_code = subdivisions[1]["iso_code"]
    if not is_in_list(province_code, provinces_allowed) then
        return 103
    end

    return 0
end

--Get the client user agent
function get_user_agent()
    USER_AGENT = ngx.var.http_user_agent
    if USER_AGENT == nil then
       USER_AGENT = ""
    end
    return USER_AGENT
end

--Get the client IP
function get_client_ip()
    local headers = ngx.req.get_headers()
    local CLIENT_IP = headers["X_Forwarded_For"]

    if length(CLIENT_IP) == 0 or CLIENT_IP == "unknown" then
        CLIENT_IP = headers["X_real_ip"]
    end

    if length(CLIENT_IP) == 0 or CLIENT_IP == "unknown" then
        CLIENT_IP  = ngx.var.remote_addr
    end

    if CLIENT_IP ~= nil and length(CLIENT_IP) >15  then
        local pos  = string.find(CLIENT_IP, ",", 1)
        CLIENT_IP = string.sub(CLIENT_IP,1,pos-1)
    end

    return CLIENT_IP
end

function get_client_domain()
    local headers = ngx.req.get_headers()
    local CLIENT_DOMAIN = headers["Host"]
    return CLIENT_DOMAIN
end

--log record for json,(use logstash codec => json)
function log_record(method, data)
    local cjson = require("cjson")
    local io = require 'io'
    local LOG_PATH = cc_redirect_log_dir
    local LOCAL_TIME = ngx.localtime()
    local CLIENT_IP = get_client_ip()
    local SERVER_NAME = ngx.var.server_name
    local USER_AGENT = get_user_agent()
    local URL = ngx.var.uri
    local USER_AGENT = get_user_agent()
    local log_json_obj = {
        local_time = LOCAL_TIME,
        client_ip = CLIENT_IP,
        server_name = SERVER_NAME,
        user_agent = USER_AGENT,
        method = method,
        url = URL,
        data = data,
    }
    local LOG_LINE = cjson.encode(log_json_obj)
    local LOG_NAME = LOG_PATH..'/'..ngx.today().."_waf.log"
    local file = io.open(LOG_NAME,"a")
    if file == nil then
        return
    end
    file:write(LOG_LINE.."\n")
    file:flush()
    file:close()
end

--is item in items or not
function is_in_list(item, items)
    local is_in = false
    for _,v in pairs(items) do
        if v == item then
            is_in = true
            break
        end
    end
    return is_in
end

-- get length of string/table/nil
function length(items)
    if not items then
        return 0
    end
    
    local items_type = type(items)
    if items_type == "nil" then
        return 0
    elseif items_type == "table" then
        local count = 0
        for k,v in pairs(items) do
            count = count + 1
        end
        return count
    elseif items_type == "string" then
        return string.len(items)
    end
end

-- split str by reps
function split(str,reps)
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end