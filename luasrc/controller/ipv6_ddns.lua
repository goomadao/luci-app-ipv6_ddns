module("luci.controller.ipv6_ddns", package.seeall)

function index()
    entry({"admin","services","ipv6_ddns"},cbi("ipv6_ddns"),_("ipv6_ddns"),90).dependent=true
    entry({"admin","services","ipv6_ddns","status"},call("status")).leaf=true
end

function status()
    local e={}
    e.running=luci.sys.call("cat /etc/crontabs/root | grep perform_ipv6_ddns > /dev/null")==0
    luci.http.prepare_content("application/json")
    luci.http.write_json(e)
end