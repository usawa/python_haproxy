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
-- Table structure for table `frontends`
--

DROP TABLE IF EXISTS `frontends`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `frontends` (
  `name` varchar(255) NOT NULL,
  `ip` varbinary(16) NOT NULL,
  `port` smallint(5) NOT NULL,
  `default_backend` varchar(255) DEFAULT NULL,
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

-- Dump completed on 2018-04-02 17:48:45
