# Introduction #

Jungle Auth uses MySQL to store subscriber and rateplan information. This is the database schema for storing that information.

2 Schemas are provided, one each for authentication and logging.
Jungle Auth should only have read access to the authentication database. This is so you can use MySQL replication to have multiple database and Jungle Auth servers for redundancy.

# Schema for authentication database #
## accesspoints ##
JungleAuth will only respond to a request from a AP if the source IP and AP MAC address match what is recorded in this table.

| **Key** | **Name** | **Type** | **Description** |
|:--------|:---------|:---------|:----------------|
| _PK_    | id       | int(11)  | Internal ID number. Auto incerments |
|         | macaddr  | varchar(12) | AP MAC address  |
|         | ipaddr   | varchat(15) | AP management IP address |
|         | descr    | text     | Friendly name / hostname |
|         | rateoverride | int(11)  | rateplan ID. See Rate Override below |

```
 CREATE TABLE `jungleauth`.`accesspoints` (
`id` INT NOT NULL AUTO_INCREMENT ,
`macaddr` VARCHAR( 12 ) NOT NULL ,
`ipaddr` VARCHAR( 15 ) NOT NULL ,
`descr` TEXT NOT NULL ,
`rateoverride` INT( 11 ),
PRIMARY KEY ( `id` ) ,
UNIQUE (
`macaddr` ,
`ipaddr`
)
) ENGINE = InnoDB 
```

### Rate Override ###
If rate override is set JungleAuth will use the whichever rate is most restrictive, normal or override.
This option is intended to be used when you have a congested AP and need to reduce per-SM speeds to increase overall fairness. The slowest rate is selected to avoid a situation where a low speed subscriber could receive a possibly higher override speed.

## rateplans ##
A rate plan is a collection of bandwidth management parameters. A radio may be assigned to one rateplan at a time.

| **Key** | **Name** | **Type** | **Description** |
|:--------|:---------|:---------|:----------------|
| _PK_    | id       | int(11)  | Internal ID number. Auto incerments |
|         |name      | varchar(20) | short name      |
|         |descr     | text     | description     |
|         | upspeed  | int(5)   | Upload speed in Kbps |
|         | downspeed | int(5)   | Download speed in Kbps |
|         | upbucket | int(10)  | Upload bucket size in Kb |
|         | downbucket | int(10)  | Download bucket size in Kb |

```
 CREATE TABLE `jungleauth`.`rateplans` (
`id` INT NOT NULL AUTO_INCREMENT ,
`name` VARCHAR( 20 ) NOT NULL ,
`descr` TEXT NOT NULL ,
`upspeed` INT( 5 ) NOT NULL ,
`downspeed` INT( 5 ) NOT NULL ,
`upbucket` INT( 10 ) NOT NULL ,
`downbucket` INT( 10 ) NOT NULL ,
PRIMARY KEY ( `id` )
) ENGINE = InnoDB 
```

## radios ##
This table lists radios that are allowed on the network and which rate they should be assigned..

| **Key** | **Name** | **Type** | **Description** |
|:--------|:---------|:---------|:----------------|
| _PK_    | id       | int(11)  | Internal ID number. Auto incerments |
|         | mac      | varchar(12) | SM MAC address  |
|         | rateplan | int(11)  | rateplans.id of rate that SM is assigned to use |

```
 CREATE TABLE `jungleauth`.`radios` (
`id` INT( 11 ) NOT NULL AUTO_INCREMENT ,
`mac` VARCHAR( 12 ) NOT NULL ,
`rateplan` INT( 11 ) NOT NULL ,
PRIMARY KEY ( `id` ) ,
INDEX rateplan_index( `rateplan` ) ,
INDEX mac_index( mac ) ,
FOREIGN KEY ( rateplan ) REFERENCES rateplans( id ) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB 
```

# Schema for logging database #