-- MySQL dump 10.13  Distrib 5.7.17, for macos10.12 (x86_64)
--
-- Host: localhost    Database: lb
-- ------------------------------------------------------
-- Server version	5.5.5-10.2.14-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `acls`
--

DROP TABLE IF EXISTS `acls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `acls` (
  `name` varchar(255) NOT NULL,
  `acl` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `backend_servers`
--

DROP TABLE IF EXISTS `backend_servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `backend_servers` (
  `backend_name` varchar(255) DEFAULT NULL,
  `server_name` varchar(255) DEFAULT NULL,
  `port` smallint(5) unsigned NOT NULL,
  `ssl` tinyint(4) DEFAULT 0,
  `ssl_verify` tinyint(4) DEFAULT 0,
  UNIQUE KEY `backend_servers_index` (`backend_name`,`server_name`),
  KEY `server_name` (`server_name`),
  CONSTRAINT `backend_servers_ibfk_1` FOREIGN KEY (`backend_name`) REFERENCES `backends` (`name`),
  CONSTRAINT `backend_servers_ibfk_2` FOREIGN KEY (`server_name`) REFERENCES `servers` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `backends`
--

DROP TABLE IF EXISTS `backends`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `backends` (
  `name` varchar(255) NOT NULL,
  `mode` enum('http','tcp','health') DEFAULT 'http',
  `balance` enum('roundrobin','static-rr','leastconn','first','source','uri','url_param','hdr','rdp-cookie') DEFAULT 'roundrobin',
  `balance_parameters` varchar(255) DEFAULT NULL,
  `default_maxconn` int(10) unsigned DEFAULT 0,
  `monitor_name` varchar(255) DEFAULT NULL,
  `redispatch` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`name`),
  KEY `monitor_idx` (`monitor_name`),
  CONSTRAINT `monitor` FOREIGN KEY (`monitor_name`) REFERENCES `monitors` (`name`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `conditions`
--

DROP TABLE IF EXISTS `conditions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conditions` (
  `name` varchar(255) NOT NULL,
  `condition` enum('if','unless') NOT NULL DEFAULT 'if',
  `criterion_id` int(11) unsigned NOT NULL,
  PRIMARY KEY (`name`),
  KEY `criterion_id_idx` (`criterion_id`),
  CONSTRAINT `criterion_id` FOREIGN KEY (`criterion_id`) REFERENCES `criteria` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `criteria`
--

DROP TABLE IF EXISTS `criteria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `criteria` (
  `id` int(10) unsigned NOT NULL,
  `negate` tinyint(4) DEFAULT 0,
  `acl_name` varchar(255) NOT NULL,
  `operator` enum('and','or') DEFAULT 'and',
  `next_criterion` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`,`next_criterion`),
  KEY `acl_idx` (`acl_name`),
  KEY `next_criterion_idx` (`next_criterion`),
  CONSTRAINT `acl` FOREIGN KEY (`acl_name`) REFERENCES `acls` (`name`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  CONSTRAINT `next_criterion` FOREIGN KEY (`next_criterion`) REFERENCES `criteria` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `defaults`
--

DROP TABLE IF EXISTS `defaults`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `defaults` (
  `mode` enum('tcp','http','health') DEFAULT NULL,
  `client_timeout` int(11) DEFAULT 60000,
  `connect_timeout` int(11) DEFAULT 4000,
  `server_timeout` int(11) DEFAULT 60000,
  `queue_timeout` int(11) DEFAULT 60000,
  `http_request_timeout` int(11) DEFAULT 5000,
  `log` varchar(1024) DEFAULT 'global',
  `log_option` enum('httplog','tcplog') DEFAULT 'httplog',
  `log_format` varchar(4096) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `frontends`
--

DROP TABLE IF EXISTS `frontends`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `frontends` (
  `name` varchar(255) NOT NULL,
  `mode` enum('tcp','http','health') DEFAULT NULL,
  `ip` varbinary(16) NOT NULL,
  `port` smallint(5) NOT NULL,
  `default_backend` varchar(255) DEFAULT NULL,
  `monitor_uri` varchar(255) DEFAULT NULL,
  `compression_algo` enum('identity','gzip','deflate','raw-deflate') DEFAULT NULL,
  `compression_type` varchar(4096) DEFAULT NULL,
  PRIMARY KEY (`name`),
  KEY `default_backend` (`default_backend`),
  CONSTRAINT `default_backend` FOREIGN KEY (`default_backend`) REFERENCES `backends` (`name`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `monitors`
--

DROP TABLE IF EXISTS `monitors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `monitors` (
  `name` varchar(255) NOT NULL,
  `kind` enum('http','tcp','ssl') NOT NULL DEFAULT 'tcp',
  `send` varchar(8192) DEFAULT NULL,
  `expect` varchar(8192) DEFAULT NULL,
  `http_disable_on_404` tinyint(1) DEFAULT 0,
  `http_send_state` tinyint(1) DEFAULT 0,
  `tcp_port` smallint(5) DEFAULT 0,
  `fall` tinyint(1) DEFAULT 3,
  `rise` tinyint(1) DEFAULT 2,
  `inter` int(11) DEFAULT 2000 COMMENT 'In milliseconds	',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servers`
--

DROP TABLE IF EXISTS `servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `servers` (
  `name` varchar(255) NOT NULL,
  `ip` varbinary(16) NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-04-07 14:44:42
