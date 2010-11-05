CREATE DATABASE `freebam`;
USE freebam;
CREATE TABLE `sm` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `mac` varchar(16) NOT NULL,
  `sup` int(5) NOT NULL,
  `sdown` int(5) NOT NULL,
  `bup` int(6) NOT NULL,
  `bdown` int(6) NOT NULL,
  `active` int(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_mac` (`mac`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

