This is a simple log analyzer for the Shibboleth IdP 2.x. Just read the
cronjob script to get an understanding of how it works. Basically, you
pipe audit logs to the shibboleth-analyze.pl program like this:

./shibboleth-analyze.pl /var/log/shibboleth/idp-audit.log -yaml

To pipe more than one log, just use a wildcard under the shell, the
shibboleth-analyze program uses the Perl diamond operator and
practically understands anything you throw at it, either as input or as
argument. 

To get the difference between two successive invocations of
shibboleth-analyze.pl, pipe its output to differ.pl, like this

./shibboleth-analyze.pl /var/log/shibboleth/idp-audit.log -yaml | ./differ.pl -d --period=9 

By default the differ will output its results into /tmp/differ-output,
but that is configurable. Take a look at the rather simple source to
figure out what can be configured until I write some documentation about
it. You are most likely to be interested in the period (minutes) which
is basically the window into the past for which statistics are calculated. 

Finally, convert the yaml output to a table like this:

yaml2table.pl /tmp/differ-output > /tmp/shib-snmp-table

You have to repeat the above procedure e.g. every 10 minutes. Run the
differ only one time for each period. Easiest way to do this is to use
the included crontab.

After understanding all the above, just put a line like that in your
snmpd.conf file:

pass .1.3.6.1.4.1.969.33 /usr/local/etc/passscripts/table1 /tmp/shib-snmp-table -t .1.3.6.1.4.1.969.33 

This will "implement" a table containing the contents of
/tmp/shib-snmp-table under the .1.3.6.1.4.1.969.33 oid. 

Hope someone finds this piece of code useful,
Athanasios Douitsis 2014
