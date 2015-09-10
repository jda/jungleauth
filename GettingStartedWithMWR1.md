# Introduction #
Basic instructions for the Minimal Working Release #1 of Jungleauth.

MWR1 includes a perl library (Net::Canopy::BAM) for parsing and identifying BAM packets. It also includes a very basic BAM server, csvserver.pl.

csvserver.pl uses a csv file as the SM database. Example CSV file:
```
0a003e903575,1544,640,51200,15360
0a003e90e6f8,768,768,768,768
```

# Requirements #
  * Perl 5.8
  * The following perl modules (some should be included with your perl, others will need to be installed from cpan)
    * Bit::Vector
    * Data::Dumper
    * IO::Socket::INET
    * Getopt::Long
    * Text::CSV

# Setup Walkthrough #
_Note: this starts after you install the perl modules_

```
YANIMB2C-2:tmp jda$ cd /tmp
YANIMB2C-2:tmp jda$ wget http://jungleauth.googlecode.com/files/jungleauth-0.01.tar.gz
YANIMB2C-2:tmp jda$ tar -xzf jungleauth-0.01.tar.gz 
YANIMB2C-2:tmp jda$ cd jungleauth/src/Net-Canopy-BAM 
YANIMB2C-2:Net-Canopy-BAM jda$ perl Makefile.PL 
YANIMB2C-2:Net-Canopy-BAM jda$ sudo make install
YANIMB2C-2:Net-Canopy-BAM jda$ cd ..
YANIMB2C-2:src jda$ perl csvserver.pl -h
YANIMB2C-2:src jda$ sudo perl csvserver.pl --smlist users.csv
```