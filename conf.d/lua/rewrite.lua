require 'init'

function main()
    -- 非主页, 不跳转
    local uris = { "/", "/index.html"}
    if not is_in_list(ngx.var.uri, uris) then
        return
    end

    local access_ip=get_client_ip()
    local access_domain=get_client_domain()
    local remain_key = access_ip .. "-" .. access_domain
    local check_result = rewrite_check(access_ip, remain_key)

    -- 检查结果非 0 时，不跳转
    if check_result ~= 0 then
        return
    end

    local limit = ngx.shared.limit

    if not limit:get(access_ip) then
        limit:set(access_ip, 1, cc_redirect_expire_time_one_ip)
    end

    if not limit:get(remain_key) then
        limit:set(remain_key, 1, cc_redirect_expire_time_one_ip)
    end
    
    limit:set("cc_redirect_pause", 1, cc_redirect_expire_time_another_ip)
    
    local now_date = get_now_date()
    
    -- 增加 PV 计数
    local pv_key = now_date .. "_pv"
    local n, e = limit:incr(pv_key, 1)
    if not n then
        limit:set(pv_key, 1)
    end
    
    -- 增加 UV 计数
    local uv_key = now_date .. "_uv"
    local uv_key_this_ip = access_ip .. "_" .. now_date
    local uv_exists = limit:get(uv_key_this_ip)
    if not uv_exists then
        limit:set(uv_key_this_ip, 1)  -- ip 标记下，下次再访问时，不执行 uv 计数

        local n, e = limit:incr(uv_key, 1)
        if not n then
            limit:set(uv_key, 1)  -- 每个 ip 访问，当日 uv 计数加 1
        end
    end

    -- 打印日志
    local request_log_t = {}
    table.insert(request_log_t, "redirect")
    table.insert(request_log_t, cc_redirect_limit)
    table.insert(request_log_t, limit:get(uv_key) or 0)  -- UV计数
    table.insert(request_log_t, limit:get(pv_key) or 0)  -- PV计数
    table.insert(request_log_t, access_ip)
    table.insert(request_log_t, access_domain)
    log_record("main", table.concat(request_log_t, "-"))
    
    -- 跳转
    return ngx.redirect(cc_redirect_url, cc_redirect_status_code)
end

main()