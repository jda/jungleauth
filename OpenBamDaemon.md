# Introduction #

open-bam-daemon.pl provides a drop-in replacement for the engine/backend component of the Motorola BAM 2.0 software.

# Prerequisites #
  * Motorola BAM 2.0 server database (tested with MySQL. May work with Postgres)
  * The following perl modules available from CPAN
    * POE
    * POE::Component::SimpleDBI
    * POE::Component::Daemon
    * IO::Socket::INET
    * Net::Canopy::BAM
    * Config::INI::Reader

# Installation #
  * Download the latest open-bam-daemon.pl from the Downloads tab on this site.
  * Install the perl components listed above
  * mark open-bam-daemon.pl as executable: chmod +x open-bam-daemon.pl

# Operation #
  * Locate the sse.conf file on your BAM server
  * Run the open bam daemon: ./open-bam-daemon.pl /path/to/sse.conf server\_IP\_address\_to\_use