# Secuip

secuip is a apache modulue which can block http requests. It has a configuration within httpd.conf.

### main features
* request block if requests which have same Client IP and same URI, exceed a spectific count
* share the request count between servers (needs a redis server)
* duration time is configurable(duration expire is supproted automatically using redis key expire)
* HTTP response code is configurable when the request is blocked.(default code is 400)

### apache versions supported
Apache httpd 2.2.x
Apache httpd 2.4.x

### dependency with external modules
#### Redis server
request counts are store in redis server and then same function servers share the request count on all servers.
#### hiredis library(redis client)
secuip uses hiredis library which is a redis client library. So, the configuration is needed by designating libhiredis.so file path.

### Installation
#### module and redis client(hiredis) installation
* git clone --recursive https://github.com/skplanet/secuip/
* build hiredis lib.: move to secuip/hiredis/ and execute make for building libhiredis.so
* build secuip: move to secuip/ and make. You can see the .libs/mod_secuip.so (apache 2.4.x)
* if you are using apache 2.2.x, use this command, make -f Makefile22.
* (Assuption: apache webserver's path is /app/apache. If it is different, you should modify Makefile, Makefile22 based on your apache directory.)
* copy two .so files to /app/apache/modules(or apache module directory).
* Intallation is doen. You should configure .so file paths in httpd.conf.(see the below)
 
#### redis server
* add a redis server ip, port and password for redis in httpd.conf.

### configuration detail
#### so library loading
* add two lines in httpd.conf(the first one is relatibe path and the second one is absolute path)


```
LoadFile   modules/libhiredis.so
LoadModule  secuip_module  modules/mod_secuip.so
```


```
LoadFile /MY_DIR/MY_SO/libhiredis.so
LoadModule secuip_module   /MY_DIR/MY_SO/mod_secuip.so 
```
 
#### Redis connection pool
Apahce initiates a redis connection pool. redis context is stored within internal queue.
Independent queue space is allocated per apache process. Initial count is SecuipRedisInitCount's value.
Place the below configuration in httpd.conf top-level.


```
SecuipRedisQueueEnabled on # secuip on or off
SecuipRedisIP 172.19.113.231 # redis IP
SecuipRedisPort 6379  # redis Port
SecuipRedisPassword "MY_REDIS_PASSWORD" # redis server password(for redis AUTH command)
SecuipRedisInitCount 5 # initial redis connection count per apache process
```

#### URI Path applied
This conf. is available within virtual host.

```
<Location URI PATH>
  SecuipEnabled on  # on or off for this path(on/off)
  SecuipDurationSecond 30 # redis key expire time(second)
  SecuipMaxCallCount 3 # Maximum request count number during SecuipDurationSecond's value.(when exceeds the number, the request is blocked during SecuipBlockSecond's value)
  SecuipBlockSecond 60 # 
  SecuipBlockResponseCode 403  # when blocked, HTTP response code for client(default 400) 
</Location>
```

According to the above, if same IP, same location uri request exceeds request counts 3 for 30 seconds, the next request(same IP, URI) will be blocked and client gets HTTP response code 403 for 60 seconds.

### logging
secuip uses the apache error log. (the below is a example log)

```
[Thu Apr 03 13:03:13 2014] [error] The FIRST request(within [30sec])(Passing count:1) [123.143.8.124_/api/login/loginPostTOI.do] [duration time:30]
[Thu Apr 03 13:03:16 2014] [error] The FIRST request(within [30sec])(Passing count:1) [112.169.60.135_/api/login/loginPostTOI.do] [duration time:30]
[Thu Apr 03 13:03:19 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:2]
[Thu Apr 03 13:03:20 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:3]
[Thu Apr 03 13:03:21 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:4]
[Thu Apr 03 13:03:22 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:5]
[Thu Apr 03 13:03:23 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:6]
[Thu Apr 03 13:03:24 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:7]
[Thu Apr 03 13:03:24 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:8]
[Thu Apr 03 13:03:25 2014] [error] Blocking [123.143.8.124_/api/login/loginPostTOI.do] [block time:1200]
[Thu Apr 03 13:03:25 2014] [error] Blocking [123.143.8.124_/api/login/loginPostTOI.do] [total req. count:9]
[Thu Apr 03 13:03:26 2014] [error] Blocking [123.143.8.124_/api/login/loginPostTOI.do] [total req. count:10]
```

 
### Todo
* query strng support for blocking element
* Almost real-time applied without restarting apache server. when URI conf. is changed.
* when blocked conditon, secuip doesn't block it and adding a specific custome request header and pass the request to back-end server.
* A specific HTTP request header support for blocking element

=============================================================

# Secuip

secuip는 HTTP 요청을 차단하는 아파치 모듈입니다. 아파치 웹서버와 함께 동작하고, 일반적으로 httpd.conf 파일에 설정 내용을 추가하여 동작시킵니다.

### secuip의 기능
* 동일 URI, 동일 IP에 대한 요청 회수 초과에 따른 접속 차단 기능
* 동일 URI, 동일 IP의 요청 정보에 대한 서버간 공유기능 제공(Redis 이용)
* 접속 차단 지속 시간 설정 가능(지속 시간 경과 후 차단 자동 해제)
* 접속 차단시 클라이언트에 전달할 응답코드 지정 기능(기본값 HTTP 응답코드 400)

### 지원하는 아파치 버전
본 모듈은 아파치 웹서버에 모듈 방식으로 추가하여 동작합니다.

Apache httpd 2.2.x

Apache httpd 2.4.x

### 외부 모듈 의존성
#### Redis 서버
secuip는 호출 회수를 Redis 서버에 저장합니다. 따라서, 동일한 기능의 여러 서버를 운영하더라도 호출 회수를 전체 서버를 기준으로 정할 수 있습니다.
secuip 모듈은 각 서버에 설치하고, 요청 회수 관리는 Redis 서버를 이용합니다. 
### hiredis 라이브러리(redis client)
secuip는 redis client 기능을 위해서 hiredis를 사용합니다. 따라서, hiredis를 빌드한 libhiredis.so 파일을 필요로 합니다.

### 설치 방법
#### 모듈 및 redis client(hiredis) 설치
* git clone --recursive https://github.com/skplanet/secuip/
* hiredis lib 빌드: secuip/hiredis/ 디렉토리로 이동하여 make 실행하면 libhiredis.so가 만들어집니다.
* 모듈빌드: secuip/ 디렉토리로 이동하여 make 실행하면 .libs/mod_secuip.so  파일이 만들어집니다.(apache 2.4.x 기준)
* (apache 2.2.x 기반이라면 make -f Makefile22 명령으로 빌드해야함)
* (아파치 설치 경로는 /app/apache 기준입니다. 다른 디렉토리에 아파치가 설치되어 있다면 Makefile, Makefile22의 내용에서 그 경로에 맞게 변경하십시오.)
* 두 개의 .so 파일을 /app/apache/modules 디렉토리(일산IDC 서버 기준)로 복사.(또는 다른 임의의 장소에 복사)
* 설치는 끝난 상태이고, .so 파일들의 위치에 따라 httpd.conf 파일을 설정해야합니다.(아래 설정방법을 참고하세요.)
 
#### redis 서버
URI 호출 회수를 저장하기 위한 redis 서버가 필요합니다.(httpd.conf 설정에 redis ip, port, 비빌번호 설정이 있어야 함) 

### 설정방법
#### so 로딩
* httpd.conf에 아래 두 라인 추가합니다.


```
LoadFile   modules/libhiredis.so
LoadModule  secuip_module  modules/mod_secuip.so
```

* 위 설정 내용은 아파치 웹서버가 설치된 경로 아래에 modules 라는 디렉토리에 2개의 so 파일들(libhiredis.so, mod_secuip.so)을 저장한 경우입니다. 다른 디렉토리에 so 파일들이 존재한다면 해당 경로의 절대로를 사용하여 설정할 수 있습니다.

```
LoadFile /MY_DIR/MY_SO/libhiredis.so
LoadModule secuip_module   /MY_DIR/MY_SO/mod_secuip.so 
```

 
#### 적용 경로 설정
* Redis connection pool 설정
아파치 웹서버 시작시 redis 서버와의 연결 pool를 생성합니다. redis 연결정보가 내부 queue에 저장됩니다.
프로세스당 독립적인 queue 공간을 활용하여 RedisInitCount 만큼의 connection를 미리 만들어 사용합니다.
아래 설정내용을 httpd.conf 최상위에 넣으십시오.


```
SecuipRedisQueueEnabled on # 본 기능 사용여부(off이면 connection pool 미사용)
SecuipRedisIP 172.19.113.231 # redis IP
SecuipRedisPort 6379  # redis Port
SecuipRedisPassword "MY_REDIS_PASSWORD" # redis 비밀번호
SecuipRedisInitCount 5 # 각 프로세스당 redis 서버에 미리 연결하는 connection 수
```

* URI 경로 지정을 위한 설정
virtual host 설정이 있는 곳에 아래 설정을 추가합니다.(예. 443 or 80 port)

```
<Location 원하는 URI 경로>
  SecuipEnabled on  # 본 경로에 대한 기능 사용(off:미사용)
  SecuipDurationSecond 30 # 동일한 요청에 대하여 요청카운트를 기록하는 시간 (초단위)
  SecuipMaxCallCount 4 # SecuipDurationSecond에 설정한 시간 이내에 본 숫자에 해당하는 요청 이상이 온 경우 차단 시작함.
  SecuipBlockSecond 60 # SecuipMaxCallCount를 초과한 경우에 이 시간(초단위) 동안에 동일 IP에서 동일 요청은 block 처리함. 이 시간이 지나면 다시 요청 허가됨.
SecuipBlockResponseCode 403  # 요청 회수 초과로 block될 경우에 서버가 클라이언트 전달하는 HTTP 응답코드(미설정시 400) 
</Location>
```

위 내용대로 설정하면 "30초 동안에 동일한 IP에서 동일한 URI 요청이 4회이상(3회 초과)이 되는 시점부터 60초간 동일한 요청은 막힙니다".
60초 이후에는 동일한 요청도 허용하도록 자동으로 복구 됩니다.

### 로깅
아래와 같은 로그가 apache error log 파일에 남습니다.

```
[Thu Apr 03 13:03:13 2014] [error] The FIRST request(within [30sec])(Passing count:1) [123.143.8.124_/api/login/loginPostTOI.do] [duration time:30]
[Thu Apr 03 13:03:16 2014] [error] The FIRST request(within [30sec])(Passing count:1) [112.169.60.135_/api/login/loginPostTOI.do] [duration time:30]
[Thu Apr 03 13:03:19 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:2]
[Thu Apr 03 13:03:20 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:3]
[Thu Apr 03 13:03:21 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:4]
[Thu Apr 03 13:03:22 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:5]
[Thu Apr 03 13:03:23 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:6]
[Thu Apr 03 13:03:24 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:7]
[Thu Apr 03 13:03:24 2014] [error] Passing [123.143.8.124_/api/login/loginPostTOI.do] [current count:8]
[Thu Apr 03 13:03:25 2014] [error] Blocking [123.143.8.124_/api/login/loginPostTOI.do] [block time:1200]
[Thu Apr 03 13:03:25 2014] [error] Blocking [123.143.8.124_/api/login/loginPostTOI.do] [total req. count:9]
[Thu Apr 03 13:03:26 2014] [error] Blocking [123.143.8.124_/api/login/loginPostTOI.do] [total req. count:10]
```

 
### Todo
* query string의 key, value에 따른 차단 기능 추가
* URI 변경 설정을 apache 재시작없이 실시간으로 적용하는 기능 추가 
* 차단 조건에 부합할 때, 차단하지 않고 특정 HTTP 헤더를 추가하고 back-end 서버로 전달하는 기능 추가
* 특정 HTTP header의 값을 key로 사용할 수 있게 하는 기능 추가

