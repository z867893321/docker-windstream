# docker-winstream
## 下载JDK1.6
下载地址 http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html#jdk-6u21-oth-JPR
## 下载 weblogic1036
下载地址http://www.oracle.com/technetwork/cn/middleware/weblogic/downloads/wls-main-091116-zhs.html
下载wls1036_dev.zip包
```
unzip wls1036_dev.zip -d weblogic1036
```
##  准备BPM的安装包
```
unzip PROGRESS_SAVVION_BUSINESSMANAGER_7.6.4_ALL.zip -d winstream
```
## 准备BPM的静默安装文件和授权文件
```
silent.xml(可自定义)
license.xml
```
## 构建镜像
```
docker build -t winstream .
```
## 使用
1. 启动winstream容器，启动之前需要确定连接的oracle服务器正常工作，winstream容器启动之后需要等待其初始化数据库的过程
```
docker run -d -p 14002:14002 -p 18793:18793 -p 16003:16003 -h hydsoft(需要和silent文件中host.name一致) winstream
```
2. start status stop winstream服务
```
docker exec -t winstream容器名 bash wsserver.sh start
docker exec -t winstream容器名 bash wsserver.sh stop
docker exec -t winstream容器名 bash wsserver.sh status
```
3. adminserver地址：http://<yourip>:14002/console
   user:system   
   passwd:wlsysadmin
   portalserver: http://<yourip>:18793/sbm/bpmportal/login.jsp
   user:ebms
   passwd: 12345678
