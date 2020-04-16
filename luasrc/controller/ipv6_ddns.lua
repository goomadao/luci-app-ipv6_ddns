module("luci.controller.ipv6_ddns", package.seeall)

function index()
    entry({"admin","ddns"},alias("admin","ddns","ipv6_ddns"),_("ipv6_ddns"),30).index=true
    entry({"admin","ddns","ipv6_ddns"},cbi("ipv6_ddns"),_("ipv6_ddns"),90).dependent=true
end