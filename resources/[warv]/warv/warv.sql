/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


CREATE TABLE IF NOT EXISTS `bans` (
  `banid` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL DEFAULT '0',
  `staffmember` varchar(50) NOT NULL DEFAULT '0',
  `reason` longtext NOT NULL,
  `banstart` int(11) NOT NULL DEFAULT '0',
  `banend` int(11) DEFAULT NULL,
  `banned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `unbanned` int(11) DEFAULT '0',
  PRIMARY KEY (`banid`),
  KEY `bans_uid` (`uid`),
  KEY `staffmember_uid` (`staffmember`),
  CONSTRAINT `bans_uid` FOREIGN KEY (`uid`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `identifiers` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `UID` int(11) NOT NULL,
  `Identifier` varchar(100) NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Identifier` (`Identifier`),
  KEY `identifiers_uid` (`UID`),
  CONSTRAINT `identifiers_uid` FOREIGN KEY (`UID`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) COLLATE utf8_bin DEFAULT '',
  `identifier` varchar(255) COLLATE utf8_bin NOT NULL,
  `discord` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `public_api` int(11) DEFAULT '1',
  `permissionLevel` int(11) NOT NULL DEFAULT '0',
  `rank` longtext COLLATE utf8_bin,
  `fivem` varchar(255) COLLATE utf8_bin DEFAULT NULL,
  `crew` varchar(4) COLLATE utf8_bin DEFAULT NULL,
  `playtime` int(11) DEFAULT '0',
  `trust_level` int(11) DEFAULT '100',
  `settings` longtext COLLATE utf8_bin,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_identifier_unique` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;

CREATE TABLE IF NOT EXISTS `warv` (
  `uid` int(11) NOT NULL AUTO_INCREMENT,
  `credit` int(11) NOT NULL DEFAULT '0',
  `emblemsId` int(11) DEFAULT NULL,
  `logoId` int(11) DEFAULT '1',
  `kill` bigint(20) DEFAULT NULL,
  `assist` bigint(20) NOT NULL DEFAULT '0',
  `death` bigint(20) DEFAULT NULL,
  `score` bigint(20) DEFAULT NULL,
  `xp` bigint(20) DEFAULT NULL,
  `level` bigint(20) DEFAULT NULL,
  `prestige` bigint(20) DEFAULT NULL,
  `ranking` bigint(20) DEFAULT NULL,
  `class` text,
  `weaponStats` text NOT NULL,
  `unlockedContent` text NOT NULL,
  `stats` text,
  UNIQUE KEY `uid` (`uid`),
  KEY `netid` (`uid`) USING BTREE,
  CONSTRAINT `warv_ibfk_1` FOREIGN KEY (`uid`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `warv_challenges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `uid` int(11) NOT NULL,
  `period` varchar(8) NOT NULL,
  `challenge` varchar(48) NOT NULL,
  `progress` int(11) NOT NULL DEFAULT '0',
  `completed` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `entry` (`uid`,`period`,`challenge`),
  KEY `uid_period` (`uid`,`period`),
  CONSTRAINT `challenges_uid_fk` FOREIGN KEY (`uid`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `warv_friends` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `requester` int(11) NOT NULL,
  `target` int(11) NOT NULL,
  `status` enum('pending','accepted','blocked') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pair` (`requester`,`target`),
  KEY `friends_requester` (`requester`),
  KEY `friends_target` (`target`),
  CONSTRAINT `friends_requester_fk` FOREIGN KEY (`requester`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `friends_target_fk` FOREIGN KEY (`target`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
