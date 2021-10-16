require 'config'
require 'lib'

function rewrite_check(access_ip)
    local limit = ngx.shared.limit

    -- 开关未开, 不跳转
    if cc_redirect_enable ~= "on" then
        return 10
    end

    -- 不在设置的时间段, 不跳转
    local now_table = os.date("*t", os.time())
    local now_date = table.concat({now_table["year"], now_table["month"], now_table["day"]})
    local now_hour = now_table["hour"]
    local now_minute = now_table["min"]

    redirect_begin_hour=tonumber(string.match(cc_redirect_period_hour, '(.*)-')) or 0
    redirect_end_hour=tonumber(string.match(cc_redirect_period_hour, '-(.*)')) or 24
    redirect_begin_minute=tonumber(string.match(cc_redirect_period_minute, '(.*)-')) or 0
    redirect_end_minute=tonumber(string.match(cc_redirect_period_minute, '-(.*)')) or 59
    local is_in_period = (now_hour >= redirect_begin_hour and now_hour <= redirect_end_hour
and now_minute >= redirect_begin_minute and now_minute <= redirect_end_minute)
    if not is_in_period then
        return 20
    end

    local now_date_value = limit:get(now_date) or 0
    -- 超过了当天最大跳转次数, 不跳转
    if now_date_value > cc_redirect_limit then
        return 30
    end

    -- 当前ip访问过的话，且没有超期的情况下，不跳转
    local one_ip_go = limit:get(access_ip)
    if one_ip_go then
        return 40
    end

    -- 上个ip跳转后一定时间段内，不跳转
    local another_ip_go = limit:get("cc_redirect_pause")
    if another_ip_go then
        return 50
    end

    -- ip不在服务区域, 不跳转
    local check_ip_code = check_ip_service_area(access_ip)
    if check_ip_code ~= 0 then
        return check_ip_code
    end

    return 0

end