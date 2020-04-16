require("luci.sys")
require("luci.sys.zoneinfo")
require("luci.tools.webadmin")
require("luci.config")
require("luci.util")
require("luci.cbi.datatypes")
require("luci.http")

local m, s, o

m =
    Map(
    "ipv6_ddns",
    translate("IPv6 DDNS"),
    translate("An IPv6 DDNS client for your router and devices using CloudFlare v4 API.")
)
m:chain("luci")

s = m:section(NamedSection, "common", "ipv6_ddns", translate("Global Settings"))
s.anonymous = true
s.addremove = false

s:tab("base",translate("Basic Settings"))
s:tab("log",translate("Log"))

enable=s:taboption("base", Flag, "enable", translate("Enable"))
enable.rmempty=false
enable.default=0

email = s:taboption("base", Value, "email", translate("Email"), translate("Your CloudFlare Email"))
function email.validate(self, value)
    if not value or not (#value > 0) then
        return nil, self.title .. translate("invalid email - Sample") .. ": 'myemail@example.com'"
    else
        return luci.util.trim(value)
    end
end

key = s:taboption("base", Value, "key", translate("Key"), translate("Your CloudFlare v4 API key"))
key.password = true
function key.validate(self, value)
    if not value or not (#value > 0) then
        return nil, self.title .. translate("can't be empty")
    else
        return luci.util.trim(value)
    end
end

log = s:taboption("log", TextValue, "log")
log.rows=26
log.wrap="off"
log.readonly=true
log.cfgvalue=function (t, t)
    return nixio.fs.readfile("/var/etc/ipv6_ddns.log") or ""
end

s = m:section(TypedSection, "service", "DDNS Services")
s.anonymous = true
s.addremove = true
s.template = "cbi/tblsection"

lookupHostname =
    s:option(
    Value,
    "lookupHostname",
    translate("Lookup Hostname"),
    translate("Hostname/FQDN to validate, if IP update happen or necessary")
)
lookupHostname.rmempty = false
lookupHostname.placeholder = "myhost.example.com"
function lookupHostname.validate(self, value)
    if not value or not (#value > 0) or not luci.cbi.datatypes.hostname(value) then
        return nil, self.title .. translate("invalid FQDN / required - Sample") .. ": 'myhost.example.com'"
    else
        return luci.util.trim(value)
    end
end

domain = s:option(Value, "domain", translate("Domain"), translate("Replaces [DOMAIN] in Update-URL"))
domain.placeholder = "myhost@example.com"
function domain.validate(self, value)
    if not value or not (#value > 0) then
        return nil, self.title .. translate("invalid domain - Sample") .. ": 'myhost@example.com'"
    else
        return luci.util.trim(value)
    end
end

device = s:option(ListValue, "device", translate("Device"))
luci.sys.net.mac_hints(
    function(x, d)
        device:value(x, "%s (%s)" % {x, d})
    end
)

lan = luci.util.ubus("network.interface.lan", "status")
ipv6_prefix = "none"
if lan and lan["ipv6-prefix-assignment"] then
    for _, a in ipairs(lan["ipv6-prefix-assignment"]) do
        if string.sub(a.address, 1, 1) == "2" then
            ipv6_prefix = a.address
            break
        end
    end
end
current_addr =
    s:option(
    DummyValue,
    "current_addr",
    translate("Prefix is ") .. ipv6_prefix 
)

local apply = luci.http.formvalue("cbi.apply")
if apply then
    io.popen("/etc/init.d/ipv6_ddns restart")
end

return m
