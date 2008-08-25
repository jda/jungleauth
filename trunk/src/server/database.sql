-- phpMyAdmin SQL Dump
-- version 2.11.3deb1ubuntu1
-- http://www.phpmyadmin.net
--
-- Host: nccmysql1.netwurx.net
-- Generation Time: Aug 24, 2008 at 10:20 PM
-- Server version: 5.0.45
-- PHP Version: 5.2.4-2ubuntu5.3

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

--
-- Database: `jungleauth`
--

-- --------------------------------------------------------

--
-- Table structure for table `accessgroupaps`
--

CREATE TABLE IF NOT EXISTS `accessgroupaps` (
  `id` int(11) NOT NULL auto_increment,
  `groupid` int(11) NOT NULL,
  `apid` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `groupid_index` (`groupid`),
  KEY `apid_index` (`apid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `accessgroupaps`
--


-- --------------------------------------------------------

--
-- Table structure for table `accessgroups`
--

CREATE TABLE IF NOT EXISTS `accessgroups` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(12) NOT NULL,
  `descr` text NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `accessgroups`
--


-- --------------------------------------------------------

--
-- Table structure for table `accesspoints`
--

CREATE TABLE IF NOT EXISTS `accesspoints` (
  `id` int(11) NOT NULL auto_increment,
  `macaddr` varchar(12) NOT NULL,
  `ipaddr` varchar(15) NOT NULL,
  `descr` text NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `macaddr` (`macaddr`,`ipaddr`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `accesspoints`
--


-- --------------------------------------------------------

--
-- Table structure for table `radioconfigs`
--

CREATE TABLE IF NOT EXISTS `radioconfigs` (
  `id` int(11) NOT NULL auto_increment,
  `mac` varchar(12) NOT NULL,
  `rateplan` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `rateplan_index` (`rateplan`),
  KEY `mac_index` (`mac`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `radioconfigs`
--


-- --------------------------------------------------------

--
-- Table structure for table `rateplans`
--

CREATE TABLE IF NOT EXISTS `rateplans` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(20) NOT NULL,
  `descr` text NOT NULL,
  `accessgroup` int(11) default NULL,
  `upspeed` int(5) NOT NULL,
  `downspeed` int(5) NOT NULL,
  `upbucket` int(10) NOT NULL,
  `downbucket` int(10) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `rateplans`
--


--
-- Constraints for dumped tables
--

--
-- Constraints for table `accessgroupaps`
--
ALTER TABLE `accessgroupaps`
  ADD CONSTRAINT `accessgroupaps_ibfk_4` FOREIGN KEY (`apid`) REFERENCES `accesspoints` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `accessgroupaps_ibfk_3` FOREIGN KEY (`groupid`) REFERENCES `accessgroups` (`id`) ON UPDATE CASCADE;

--
-- Constraints for table `radioconfigs`
--
ALTER TABLE `radioconfigs`
  ADD CONSTRAINT `radioconfigs_ibfk_1` FOREIGN KEY (`rateplan`) REFERENCES `rateplans` (`id`) ON UPDATE CASCADE;

