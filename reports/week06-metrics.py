import json, urllib.request
URL = "http://localhost:8080/api_jsonrpc.php"
def call(method, params, auth=None):
    body = {"jsonrpc": "2.0", "method": method, "params": params, "id": 1}
    if auth: body["auth"] = auth
    req = urllib.request.Request(URL, json.dumps(body).encode(), {"Content-Type": "application/json-rpc"})
    return json.load(urllib.request.urlopen(req))["result"]
token = call("user.login", {"user": "Admin", "password": "zabbix"})
wanted = ["CPU utilization", "Load average (1m avg)", "Memory utilization", "Uptime",
          "/: Space utilization", "Interface eth0(): Bits received", "Interface eth0(): Bits sent",
          "Interface eth1(): Bits received", "Interface eth1(): Bits sent", "ICMP response time"]
for host in ["web1", "db1", "branch-client"]:
    items = call("item.get", {"host": host, "output": ["name", "lastvalue", "units"]}, token)
    print(f"## {host}")
    for name in wanted:
        for i in items:
            if i["name"] == name:
                print(f"{name:35} {i['lastvalue']} {i['units']}")
    print()
