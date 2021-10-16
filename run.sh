#!/bin/bash

replace_config_file() {
    if [ $ENVIRONMENT_NAME ] && [ ! -z $ENVIRONMENT_NAME ]; then
        config_file="environments/$ENVIRONMENT_NAME.lua"
        echo "use proper config file -- $config_file"
        if [ -f "$config_file" ]; then
            \cp $config_file conf.d/lua/config.lua
        else
            echo "$config_file does not exist"
        fi
    else
        echo "use default config file -- conf.d/lua/config.lua"
    fi
}

mkdir -p /etc/nginx/conf.d/lua

replace_config_file
cp -r conf.d/* /etc/nginx/conf.d/

# cp conf.d/default.conf.bak /etc/nginx/conf.d/default.conf

exit 0