-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: labinventory
-- ------------------------------------------------------
-- Server version	8.0.41

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `borrowtransaction`
--

DROP TABLE IF EXISTS `borrowtransaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `borrowtransaction` (
  `TransactionID` int NOT NULL AUTO_INCREMENT,
  `StudentID` int DEFAULT NULL,
  `ManagerID` int DEFAULT NULL,
  `RequestDate` datetime DEFAULT CURRENT_TIMESTAMP,
  `DueDate` datetime DEFAULT NULL,
  `ReturnDate` datetime DEFAULT NULL,
  `Status` enum('Pending','Approved','Rejected','Returned') DEFAULT 'Pending',
  PRIMARY KEY (`TransactionID`),
  KEY `StudentID` (`StudentID`),
  KEY `ManagerID` (`ManagerID`),
  CONSTRAINT `borrowtransaction_ibfk_1` FOREIGN KEY (`StudentID`) REFERENCES `student` (`StudentID`),
  CONSTRAINT `borrowtransaction_ibfk_2` FOREIGN KEY (`ManagerID`) REFERENCES `labmanager` (`ManagerID`)
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `borrowtransaction`
--

LOCK TABLES `borrowtransaction` WRITE;
/*!40000 ALTER TABLE `borrowtransaction` DISABLE KEYS */;
INSERT INTO `borrowtransaction` VALUES (1,1,1,'2025-03-26 13:15:25','2025-03-10 00:00:00',NULL,'Pending'),(2,2,2,'2025-03-26 13:15:25','2026-03-28 12:00:00',NULL,'Approved'),(4,3,1,'2025-03-01 00:00:00','2026-03-20 00:00:00',NULL,'Rejected'),(5,1005,NULL,'2025-04-10 21:15:31',NULL,NULL,'Rejected'),(6,1005,NULL,'2025-04-10 21:15:36',NULL,NULL,'Rejected'),(7,1005,NULL,'2025-04-10 21:16:41',NULL,NULL,'Rejected'),(8,1005,NULL,'2025-04-10 21:16:48','2025-04-11 00:00:00',NULL,'Returned'),(9,1005,NULL,'2025-04-10 21:27:15','2025-04-11 00:00:00',NULL,'Returned'),(10,1005,NULL,'2025-04-10 21:40:54',NULL,NULL,'Rejected'),(11,1005,NULL,'2025-04-10 22:49:05','2025-04-12 00:00:00',NULL,'Returned'),(12,1005,NULL,'2025-04-10 23:10:26',NULL,NULL,'Pending'),(13,1006,NULL,'2025-04-11 01:44:12','2025-04-15 18:00:00',NULL,'Returned'),(14,1006,NULL,'2025-04-14 12:05:25','2025-04-15 17:05:00',NULL,'Returned'),(15,1007,NULL,'2025-04-14 12:08:06','2025-04-17 12:08:00',NULL,'Returned'),(16,1007,NULL,'2025-04-14 12:29:41','2025-04-14 12:29:00',NULL,'Returned'),(17,1007,NULL,'2025-04-14 12:42:32','2025-04-15 12:42:00',NULL,'Returned'),(18,1007,NULL,'2025-04-14 13:15:28',NULL,NULL,'Rejected'),(19,1007,NULL,'2025-04-14 13:19:37','2025-04-15 13:19:00',NULL,'Returned');
/*!40000 ALTER TABLE `borrowtransaction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `labmanager`
--

DROP TABLE IF EXISTS `labmanager`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `labmanager` (
  `ManagerID` int NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) DEFAULT NULL,
  `Contact` varchar(100) DEFAULT NULL,
  `Password` varchar(255) NOT NULL,
  `role` varchar(20) DEFAULT 'LabManager',
  PRIMARY KEY (`ManagerID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `labmanager`
--

LOCK TABLES `labmanager` WRITE;
/*!40000 ALTER TABLE `labmanager` DISABLE KEYS */;
INSERT INTO `labmanager` VALUES (1,'Engr. Mark Tan','mark.tan@uc.edu.ph','scrypt:32768:8:1$CBC6jAFcGrrz61fj$d66b35a06a60dbe7c75c21291ea882706a72b115c0b641e03aab50dd7ad1ca76ecec6fbf9592bcb06de9cd39f4881cdfeb21ff53d7a07d6e0124f2fdefe71ed8','Admin'),(2,'Engr. Anna Velasco','anna.velasco@uc.edu.ph','scrypt:32768:8:1$eeVFug6UaRveadQv$6a016d5eea9bc40bdb2064501f2636fbb5514786c211cf63472c49dcd75fa2d7c03eb8843a6009c620b2523ab06ab58a69af8fe3c1aadd588a875faad09bec4a','LabManager'),(3,'Admin','Admin@UC','scrypt:32768:8:1$4eOQBLTSQMbcBM9x$bb72b75c31e7caff3a604339a2dc5d41a92a7d4276c642ca223fa836c582f751193285bdcb8daa1ad3798adc174661307139d9f031f250e55321992ed4d9feaf','Admin');
/*!40000 ALTER TABLE `labmanager` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `material`
--

DROP TABLE IF EXISTS `material`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `material` (
  `MaterialID` int NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) DEFAULT NULL,
  `Description` text,
  `StockQuantity` int DEFAULT '0',
  PRIMARY KEY (`MaterialID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `material`
--

LOCK TABLES `material` WRITE;
/*!40000 ALTER TABLE `material` DISABLE KEYS */;
INSERT INTO `material` VALUES (1,'Multimeter','Digital multimeter for measuring voltage, current, and resistance.',17),(2,'Soldering Iron','Electric tool for soldering components.',26),(3,'Breadboard','Prototyping board for circuits.',25),(4,'Arduino Uno','Microcontroller development board.',11),(8,'Chicken','A dummy item made by Jansen Bryle',17),(10,'MTS','A microcontroller',5);
/*!40000 ALTER TABLE `material` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `NotificationID` int NOT NULL AUTO_INCREMENT,
  `Message` varchar(255) NOT NULL,
  `ReadStatus` tinyint(1) DEFAULT '0',
  `CreatedAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`NotificationID`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (1,'New borrow request approved!',1,'2025-04-10 13:24:51'),(2,'New borrow request approved!',1,'2025-04-10 13:27:44'),(3,'New borrow request approved!',0,'2025-04-10 15:02:00'),(4,'New borrow request approved!',0,'2025-04-14 04:04:10'),(5,'New borrow request approved!',0,'2025-04-14 04:05:37'),(6,'New borrow request approved!',0,'2025-04-14 04:08:21'),(7,'New borrow request approved!',0,'2025-04-14 04:29:51'),(8,'New borrow request approved!',0,'2025-04-14 04:42:44'),(9,'New borrow request approved!',0,'2025-04-14 05:19:57');
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student`
--

DROP TABLE IF EXISTS `student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student` (
  `StudentID` int NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) DEFAULT NULL,
  `Email` varchar(100) DEFAULT NULL,
  `Course` varchar(100) DEFAULT NULL,
  `Year` varchar(50) DEFAULT NULL,
  `Password` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`StudentID`),
  UNIQUE KEY `Email` (`Email`)
) ENGINE=InnoDB AUTO_INCREMENT=1008 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student`
--

LOCK TABLES `student` WRITE;
/*!40000 ALTER TABLE `student` DISABLE KEYS */;
INSERT INTO `student` VALUES (1,'Alice Dela Cruz','alice.dc@student.uc.edu.ph','BSCpE','1st Year','scrypt:32768:8:1$8BBs3aFGrluetI34$865e37f06bff7d6f53ecbaab35425329a919bb0469f1faf2862fc16f238d9c22a51fadd8378f56fc4697aba739fc402cb85ab4e2f993e0d6ea272045363f7fc2'),(2,'Bryan Reyes','bryan.reyes@student.uc.edu.ph','BSCpE','2nd Year','scrypt:32768:8:1$68XIsfSne54VZYTm$29dee499f4251e25d67af44e2581768335d70d6cd8ca0b3075f969beae097cb1631cef6dc86709d8f2274b0991a2d232a7b151f5ab47260ad0f470cd70affef0'),(3,'Cathy Torres','cathy.torres@student.uc.edu.ph','BSEE','2nd Year','scrypt:32768:8:1$SzxMgvi1VGmnULhp$cb266d9739e8ae13982036b2d5970b454e1dfe846aae0363a36103e1741f15a197ab57f5ea3f118a83ca403957c1ffad911a875b1012f606be66fceed3983a85'),(1005,'Chance Garcia','Chancegarcia@gmail.com','BFA','1st Year','scrypt:32768:8:1$zqcxWCU6eejXixKU$fd2f8497abe8a8898e1462057a27f8b5b269906df88c5f348c3c65f05ac1a4f9fefece3d719e4af29e0a6336883f2b1a772dd751169ac685d7c85698f8eb16c0'),(1006,'Felix Kjellberg','Felix.Kjellberg@student.uc.edu.ph','BSEP','3rd Year','scrypt:32768:8:1$55ls2DOxFPaqm4Ie$07c7adadd5a3f683bc7903362c9dc32c3be1e8c0714e70ad2dfe1d48a06a4e3cc73e9deb97d6da0dcd2244d6b58b3c1a97313d8d65f95610197b768a3a42e0b5'),(1007,'Andrei Beray','AndreiBeray@UC','BSCpE','3rd Year','scrypt:32768:8:1$v0zoy7ZnOjF2uYzk$a116c49a01b18f7adea30476c7c14bf04f4e92a31a9bd3c09a29481c24887e850dd7d980ee4e2eaa47fcdf1a694c33d4f129126f4009d0c21618a2e2076db799');
/*!40000 ALTER TABLE `student` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `studentnotifications`
--

DROP TABLE IF EXISTS `studentnotifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `studentnotifications` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `StudentID` int DEFAULT NULL,
  `NotificationID` int DEFAULT NULL,
  `ReadStatus` tinyint(1) DEFAULT '0',
  `Message` text,
  `CreatedAt` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `StudentID` (`StudentID`),
  KEY `NotificationID` (`NotificationID`),
  CONSTRAINT `studentnotifications_ibfk_1` FOREIGN KEY (`StudentID`) REFERENCES `student` (`StudentID`),
  CONSTRAINT `studentnotifications_ibfk_2` FOREIGN KEY (`NotificationID`) REFERENCES `notifications` (`NotificationID`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `studentnotifications`
--

LOCK TABLES `studentnotifications` WRITE;
/*!40000 ALTER TABLE `studentnotifications` DISABLE KEYS */;
INSERT INTO `studentnotifications` VALUES (1,1005,NULL,0,'Your borrow request has been submitted.','2025-04-10 21:40:54'),(2,1005,NULL,0,'Your borrow request has been submitted.','2025-04-10 22:49:05'),(3,1005,NULL,0,'Your borrow request has been submitted.','2025-04-10 23:10:26'),(4,1006,NULL,0,'Your borrow request has been submitted.','2025-04-11 01:44:12'),(5,1006,NULL,0,'Your borrow request has been submitted.','2025-04-14 12:05:25'),(6,1007,NULL,0,'Your borrow request has been submitted.','2025-04-14 12:08:06'),(7,1007,NULL,0,'Your borrow request has been submitted.','2025-04-14 12:29:41'),(8,1007,NULL,0,'Your borrow request has been submitted.','2025-04-14 12:42:32'),(9,1,NULL,0,'Hello Alice Dela Cruz,\n\nThis is a reminder that the following items you borrowed are overdue:\nMultimeter, Breadboard, Multimeter, Breadboard, Multimeter, Breadboard, Multimeter, Breadboard, Multimeter, Breadboard\nDue Date: 2025-03-10 00:00:00\n\nPlease return them as soon as possible. Thank you!','2025-04-14 12:52:25'),(10,1,NULL,0,'Hello Alice Dela Cruz,\n\nThis is a reminder that the following items you borrowed are overdue:\n5x Multimeter, 5x Breadboard\nDue Date: 2025-03-10 00:00\n\nPlease return them as soon as possible. Thank you!','2025-04-14 13:04:30'),(11,1,NULL,0,'Hello Alice Dela Cruz,\n\nThis is a reminder that the following items you borrowed are overdue:\n5x Multimeter, 5x Breadboard\nDue Date: 2025-03-10 00:00\n\nPlease return them as soon as possible. Thank you!','2025-04-14 13:04:33'),(12,1007,NULL,0,'Your borrow request has been submitted.','2025-04-14 13:15:28'),(13,1007,NULL,0,'Your borrow request has been submitted.','2025-04-14 13:19:37');
/*!40000 ALTER TABLE `studentnotifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactiondetail`
--

DROP TABLE IF EXISTS `transactiondetail`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactiondetail` (
  `DetailID` int NOT NULL AUTO_INCREMENT,
  `TransactionID` int DEFAULT NULL,
  `MaterialID` int DEFAULT NULL,
  `Quantity` int DEFAULT NULL,
  PRIMARY KEY (`DetailID`),
  KEY `TransactionID` (`TransactionID`),
  KEY `MaterialID` (`MaterialID`),
  CONSTRAINT `transactiondetail_ibfk_1` FOREIGN KEY (`TransactionID`) REFERENCES `borrowtransaction` (`TransactionID`),
  CONSTRAINT `transactiondetail_ibfk_2` FOREIGN KEY (`MaterialID`) REFERENCES `material` (`MaterialID`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactiondetail`
--

LOCK TABLES `transactiondetail` WRITE;
/*!40000 ALTER TABLE `transactiondetail` DISABLE KEYS */;
INSERT INTO `transactiondetail` VALUES (1,1,1,1),(2,1,3,1),(3,2,4,1),(4,1,1,1),(5,1,3,1),(6,2,4,1),(7,1,1,1),(8,1,3,1),(9,2,4,1),(10,1,1,1),(11,1,3,1),(12,2,4,1),(13,1,1,1),(14,1,3,1),(15,2,4,1),(17,5,4,2),(18,6,4,2),(19,7,3,2),(20,8,4,1),(21,8,3,2),(22,9,3,1),(23,10,3,1),(24,11,1,3),(25,12,8,5),(26,13,2,2),(27,14,2,4),(28,15,8,5),(29,16,2,1),(30,17,2,13),(31,18,2,28),(32,19,2,26);
/*!40000 ALTER TABLE `transactiondetail` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-04-14 13:30:25
