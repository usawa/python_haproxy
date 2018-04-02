import ipaddress
import io # StringIO
import mysql.connector as mariadb
import re

# haproxy defs
haproxy_modes=['http','tcp','health']
haproxy_monitor_modes=['http','tcp', 'ssl']
haproxy_balances=['roundrobin','static-rr','leastconn','first','source','uri','url_param','hdr','rdp-cookie']
haproxy_compression_algorithms=['identity','gzip','deflate','raw-deflate']

"""
brew install mariadb 

mysql.server start

mysql -u root


brew upgrade mariadb
A "/etc/my.cnf" from another install may interfere with a Homebrew-built
server starting up correctly.

MySQL is configured to only allow connections from localhost by default

To connect:
    mysql -uroot

To have launchd start mariadb now and restart at login:
  brew services start mariadb
Or, if you don't want/need a background service you can just run:
  mysql.server start
  
  
create database lb;

grant all on lb.* to lbuser@localhost identified by "lbuser";


Monitor :
 - kind (http) (tcp), ...
 - Check string
 - Check results
 - interval
 - fall
 - rise
 - timeout
 
Backend Server :
 - name
 - ip
 
Backend :
 - name
 - balance
 - type (http, tcp, ...)
 - monitor 
 - options
 - persistence
 
monitors in backend
 - backend_name
 - monitor_name
 
servers in backend 
 - backend_name
 - server_name
 - port
 - weight
 - (no)ssl
 - cookie name
 
Session persistence
 - kind (cookie, header, ...)
 - options
 

Frontends
 - name
 - ip
 - port
 - default backend

"""
class db_storage:

    conn = False
    cursor = False

    def __init__(self, name="lb"):
        self.conn = False
        self.cursor = False

        if(name):
            self.open(name)

    def __enter__(self):
        return self


    def __exit__(self):
        self.close()


    def open(self, name):
        try:
            self.conn = mariadb.connect(user="lbuser", password="lbuser", host="localhost", database=name);
            self.cursor = self.conn.cursor(buffered=True)

        except mariadb.Error as error:
            print("Error connecting to database!")


    def execute(self, command):
        if command:
            self.cursor.execute(command)

    def fetch(self):
            return self.cursor.fetchone()

    def commit(self):
        self.conn.commit()

    def close(self):
        self.conn.commit()
        self.cursor.close()
        self.conn.close()


"""
    def create_scheme(self, name="lb_api.db.sql"):
        if self.conn == None:
            return 1

        try:
            file = open(name, "r")
            sql = file.read()
            if sql:
                self.conn.executescript(sql)
        except:
            print("Not able to import scheme")
            return 1

"""

x = db_storage()

def add_server(name=None, ip=None):
    if not name or not ip:
        print("invalid name or ip")
        return 1

    # Check if IP
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        print('Invalid address: ', ip)
        return 2

    # Insert Server
    try:
        sql="insert into servers (name, ip) values ('"+name+"', '"+ip+"') " \
        "on duplicate key update ip='"+ip+"'"

        x.execute(sql)
    except mariadb.errors.IntegrityError:
        print("Server already exists")
        return 3


def add_backend(name=None, mode="http", balance="roundrobin", balance_parameters="", monitor_name="", default_maxconn=0, redispatch=True):
    if not name:
        print("invalid name")
        return 1

    # check mode
    if mode not in haproxy_modes:
        print("Invalid mode")
        return 1


    # Insert or update Server
    try:
        sql="insert into backends " \
            "(`name`, `mode`, `balance`, `balance_parameters`, `monitor_name`, `default_maxconn`, `redispatch`) " \
            "values ('"+name+"', " \
                            "'"+mode+"', " \
                            "'"+balance+"', " \
                            "'"+balance_parameters+"', " \
                            "" +("'"+monitor_name+"'" if monitor_name else "NULL")+", " \
                            "'"+str(default_maxconn)+"', " \
                            ""+str(bool(redispatch))+") " \
            "on duplicate key update " \
                            "`mode`='"+mode+"', " \
                            "`balance`='"+balance+"', " \
                            "`balance_parameters`='"+balance_parameters+"', " \
                            "`monitor_name`="+( "'"+monitor_name+"'" if monitor_name else "NULL") +", " \
                            "`default_maxconn`='"+str(default_maxconn)+"', " \
                            "`redispatch`="+str(bool(redispatch))

        #print(sql)
        x.execute(sql)
    except mariadb.errors.IntegrityError:
        print("Backend already exists")
        return 3

def add_server_to_backend(backend_name=None, server_name=None, port=None, ssl=False, ssl_verify=False):
    if not backend_name or not server_name or not port:
        print("invalid parameters")
        return 1

    if ssl>0:
        ssl = 1

    # Insert or update Server in backend
    try:
        sql= "insert into backend_servers (" \
                "`backend_name`, " \
                "`server_name`, " \
                "`port`, " \
                "`ssl`, " \
                "`ssl_verify`) " \
             "values (" \
                "'" + backend_name + "', " \
                "'" + server_name + "', " \
                "'" + str(port) + "', " \
                "" + str(bool(ssl)) + ", "\
                "" + str(bool(ssl_verify)) + ") " \
             "on duplicate key update " \
                "`port`='"+str(port)+"', " \
                "`ssl`="+str(bool(ssl)) + ", " \
                "`ssl_verify`="+str(bool(ssl_verify)) + ""

        #print(sql)
        x.execute(sql)
    except mariadb.errors.IntegrityError as Error:
        print("Integrity error: ", Error)
        return 3

""" 
    Add a monitor.
    Monitor can be :
        - tcp
        - http
        - ssl
    Two mandatory parameters : name, kind
    We can send a string (tcp or http), and expect a result.
    For now we do simple things.
    In the future, wa can expect to create complex healthchecks with multiple send and expects 
    (for example, expect a specific return code with a specific content, which is not possible
    with http-expect, but possible with tcp-expect)
"""
def add_monitor(name=None, kind=None, send="", expect="", fall=3, rise=2, inter=2000, http_disable_on_404=False, http_send_state=False, tcp_port=0):
        if not name or not kind:
            print("invalid name or kind")
            return 1

        if kind not in haproxy_monitor_modes:
            print("invalid monitor mode")
            return 1

        # Insert Server
        try:
            sql = "insert into monitors (" \
                    "`name`, " \
                    "`kind`, " \
                    "`send`, " \
                    "`expect`, " \
                    "`http_disable_on_404`, " \
                    "`http_send_state`, " \
                    "`tcp_port`, " \
                    "`fall`, " \
                    "`rise`, " \
                    "`inter`" \
                  ") values " \
                    "('" + name + "', " \
                    "'" + kind + "', " \
                    "'" + repr(send)[1:-1] + "', " \
                    "'" + expect + "', " \
                    "" + str(bool(http_disable_on_404)) + ", " \
                    "" + str(bool(http_send_state)) + ", "\
                    "'" + str(tcp_port)+"', " \
                    "'" + str(fall) + "', " \
                    "'" + str(rise) + "', " \
                    "'" + str(inter) + "') " \
                "on duplicate key update " \
                    "`kind`='" + kind+ "', " \
                    "`send`='"+send+"', " \
                    "`expect`='"+expect+"', " \
                    "`http_disable_on_404`="+str(bool(http_disable_on_404))+", " \
                    "`http_send_state`="+str(bool(http_send_state))+", " \
                    "`tcp_port`='"+str(tcp_port)+"', " \
                    "`fall`='" + str(fall) + "', " \
                    "`rise`='" + str(rise) + "', " \
                    "`inter`='" + str(inter) + "'"

            #print(sql)
            x.execute(sql)
        except mariadb.errors.IntegrityError:
            print("Monitor already exists")
            return 3

def add_frontend(name=None, mode='http', ip=None, port=None, default_backend=None, compression_algo=None, monitor_uri=None):
    if not name or not ip or not port or not default_backend:
        print("invalid frontend parameters")
        return 1

    if mode not in haproxy_modes:
        print("invalid frontend mode")
        return 1

    if compression_algo and compression_algo not in haproxy_compression_algorithms:
        print("Unknwown compression algo")
        return 1

    # Check if IP
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        print('Invalid address: ', ip)
        return 2

    # Insert Server
    try:
        sql = "insert into frontends (" \
                    "`name`, " \
                    "`mode`, " \
                    "`ip`, " \
                    "`port`, " \
                    "`default_backend` " \
                ") values " \
                    "('" + name + "', " \
                    "'" + mode + "', " \
                    "'" + ip + "', " \
                    "'" + str(port) + "', " \
                    "'" + default_backend + "') " \
                "on duplicate key update " \
                    "`mode`='" + mode + "', " \
                    "`ip`='" + ip + "', " \
                    "`port`='" + str(port) + "', " \
                    "`default_backend`='" + default_backend + "'"

        #print(sql)
        x.execute(sql)
    except mariadb.errors.IntegrityError:
        print("Frontend already exists")
        return 3

def generate_defaults():

    output= io.StringIO()

    sql= "select * from defaults"
    x.execute(sql)
    row=x.fetch()

    if not row:
        print("Error in select defaults")
        return 1

    ( mode,
      client_timeout,
      connect_timeout,
      server_timeout,
      queue_timeout,
      http_request_timeout
    )=row

    print("defaults", file=output)

    print("\ttimeout client {:d}".format(client_timeout), file=output)
    print("\ttimeout server {:d}".format(server_timeout), file=output)
    print("\ttimeout connect {:d}".format(connect_timeout), file=output)
    print("\ttimeout queue {:d}".format(queue_timeout), file=output)
    print("\ttimeout http-request {:d}".format(http_request_timeout), file=output)

    return (output.getvalue())

def generate_frontend_configuration(frontend_name=None):
    output = io.StringIO()

    if not frontend_name:
        print("No frontend name defined")
        return 1

    sql="SELECT " \
            "name," \
            "mode," \
            "ip," \
            "port, " \
            "default_backend " \
        "FROM frontends " \
        "WHERE name='"+frontend_name+"'"

    x.execute(sql)

    row = x.fetch()
    while row is not None:
        (frontend_name,
         mode,
         ip,
         port,
         default_backend)=row
        row = x.fetch()

    print("frontend frontend_{:s}".format(frontend_name), file=output)

    print("\tmode {:s}".format(mode), file=output)

    print("\tbind {:s}:{:d}".format(ip.decode(), port), file=output)

    print("\tdefault_backend backend_{:s}".format(default_backend), file=output)

    return (output.getvalue())


def generate_backend_configuration(backend_name=None):
    balance=None
    balance_parameters=None
    mode=None
    balance_string=""
    default_maxconn=0
    monitor_name=""
    redispatch=0

    output = io.StringIO()

    if not backend_name:
        print("No name defined")

    sql="SELECT " \
            "name," \
            "mode," \
            "balance," \
            "balance_parameters," \
            "default_maxconn," \
            "monitor_name," \
            "redispatch " \
        "FROM backends " \
        "WHERE " \
        "name='"+backend_name+"'"

    x.execute(sql)

    row = x.fetch()
    while row is not None:
        (backend_name,
         mode,
         balance,
         balance_parameters,
         default_maxconn,
         monitor_name,
         redispatch)=row
        row = x.fetch()

    print("backend backend_{:s}".format(backend_name), file=output)
    print("\tmode {:s}".format(mode), file=output)

    # Balance, check parameters
    if balance == "hdr" or balance == "rdp-cookie":
        if balance_parameters is not None:
            for index, parameter in enumerate(balance_parameters.split(" ")):
                if index == 0:
                    balance_string=balance+"("+parameter+")"
                else:
                    balance_string=balance_string+" "+parameter

        else:
            print ("Error: balance needs a parameter")
    else:
        balance_string=balance

    print("\tbalance {:s}".format(balance_string), file=output)

    # Redispatch
    if redispatch:
        print("\toption redispatch", file=output)
    # monitor
    if monitor_name:
        sql="select * from monitors where name='"+monitor_name+"'"
        x.execute(sql)
        row = x.fetch()
        (monitor_name,
        monitor_kind,
        monitor_send,
        monitor_expect,
        monitor_http_disable_on_404,
        monitor_http_send_state,
        monitor_tcp_port,
        monitor_fall,
        monitor_rise,
        monitor_inter)=row

        # http check
        if monitor_kind == "http":
            print("\toption httpchk {:s}".format(repr(monitor_send)[1:-1].replace(" ","\ ")), file=output)

            if monitor_http_disable_on_404:
                print("\thttp-check disable-on-404", file=output)

            if monitor_http_send_state:
                print("\thttp-check send-state", file=output
                      )

            if monitor_expect:
                print("\toption http-check expect {:s}".format(monitor_expect), file=output)
        # tcp check
        if monitor_kind == "tcp":
            print("\toption tcpchk", file=output)

        # ssl check
        if monitor_kind == "ssl":
            print("\toption ssl-hello-chk",file=output)

        print("\tdefault-server fall {:d} rise {:d} inter {:d}ms".format(monitor_fall,monitor_rise, monitor_inter),
              "port {:d}".format(monitor_tcp_port) if monitor_tcp_port != 0 else "",
              "maxconn {:d}".format(default_maxconn) if default_maxconn > 0 else "",
              file=output)

    sql="select t2.name as server, t2.ip as ip, t1.port as port, t1.ssl as `ssl`, t1.ssl_verify as `ssl_verify` " \
        "from backend_servers as t1, servers as t2 " \
        "where t1.backend_name='"+backend_name+"' and t1.server_name = t2.name"

    x.execute(sql)
    row = x.fetch()
    while row is not None:
        (
            server_name,
            ip,
            port,
            ssl,
            ssl_verify
        )=row

        print("\tserver {:s} {:s}:{:d} {:s} {:s} {:s}".format(
            server_name,ip.decode(),
            port, "ssl" if ssl else "",
            "check" if monitor_name else "",
            "verify required" if ssl_verify else "verify none",
            ),
            file=output)

        row = x.fetch()

    return (output.getvalue())





add_server(name="riri",ip="15.235.15.20")
add_server(name="fifi",ip="10.235.15.21")
add_server(name="loulou",ip="10.235.15.22")

string="GET\ /\ HTTP/1.1\r\nHost:\ www.permisinternet.fr\r\nConnection:\ close\r\nBeli-Destroy-Session:\ true\r\n"
add_monitor(name="http_check",kind="http",send=string, expect="", fall=2, rise=1, inter=2000, http_disable_on_404=True, http_send_state=True, tcp_port=0)

add_backend(name="test", mode="http",balance="roundrobin",monitor_name="http_check",redispatch=True)


add_server_to_backend(backend_name="test",server_name="riri",port=80,ssl=False)
add_server_to_backend(backend_name="test",server_name="fifi",port=80,ssl=False)
add_server_to_backend(backend_name="test",server_name="loulou",port=80,ssl=False)

add_frontend(name="mybackend", mode='http', ip="127.0.0.1", port="8080", default_backend="test")

print(generate_defaults())
print(generate_frontend_configuration("mybackend"))
print(generate_backend_configuration(backend_name="test"))


x.close()
