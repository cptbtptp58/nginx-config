require 'init'

function main()
    -- 非主页, 不跳转
    local uris = { "/", "/index.html"}
    if not is_in_list(ngx.var.uri, uris) then
        return
    end

    local access_ip=get_client_ip()
    local check_result = rewrite_check(access_ip)
    if check_result == 0 then
        -- 跳转前给ip设置超期时间, 累计当天总跳转次数, 设置跳转过期时间
        local limit = ngx.shared.limit
        local now_date = get_now_date()
        limit:set(access_ip, 1, cc_redirect_expire_time_one_ip)
        limit:set("cc_redirect_pause", 1, cc_redirect_expire_time_another_ip)
        local n, e = limit:incr(now_date, 1)
        if not n then
            limit:set(now_date, 1)
        end

        -- 打印日志
        local request_log_t = {}
        table.insert(request_log_t, "redirect")
        table.insert(request_log_t, cc_redirect_limit)
        table.insert(request_log_t, limit:get(now_date))
        table.insert(request_log_t, access_ip)
        log_record("main", table.concat(request_log_t, "-"))
        
        -- 跳转
        return ngx.redirect(cc_redirect_url, cc_redirect_status_code)
    else
        return
    end
end

main()