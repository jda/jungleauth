# Introduction #

FreeBAM provides a Canopy authentication server.

# Prerequisites #
  * MySQL Database server
  * The following perl modules available from CPAN
    * DBD::MySQL
    * POE
    * POE::Component::SimpleDBI
    * POE::Component::Daemon
    * IO::Socket::INET
    * Net::Canopy::BAM
    * Config::INI::Reader

# Installation #
  * Download the latest freebam from the Downloads tab on this site.
  * Install the perl components listed above
  * Unpack the freebam distribute: tar -xzvf freebam-ver.tgz
  * mark freebam.pl as executable: chmod +x freebam.pl

# Operation #
  * Change the settings in freebam.ini to match your database server.
  * run the SQL in freebam.sql on your MySQL server to create the database
  * Run the free(dom) BAM daemon: ./freebam.pl freebam.ini IP\_ADDR\_TO\_USE