# -*- mode: cperl -*-
# ${license-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/modules";
use CAF::RuleBasedEditor qw(:rule_constants);
use Readonly;
use CAF::Object;
use Test::More tests => 36;
use Test::NoWarnings;
use Test::Quattor;
use Test::Quattor::Object;
use Carp qw(confess);

Test::NoWarnings::clear_warnings();


=pod

=head1 SYNOPSIS

Basic tests for rule-based editor (variable substitution)

=cut

Readonly my $DPM_CONF_FILE => "/etc/sysconfig/dpm";
Readonly my $DMLITE_CONF_FILE => "/etc/httpd/conf.d/zlcgdm-dav.conf";
Readonly my $DPM_SHIFT_CONF_FILE => "/etc/shift.conf";
Readonly my $XROOTD_CONF_FILE => "/etc/xrootd/xrootd.cfg";

Readonly my $DPM_INITIAL_CONF_1 => '# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="no"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

#ALLOW_COREDUMP="no"

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
#export GLOBUS_THREAD_MODEL=pthread
';

Readonly my $DPM_INITIAL_CONF_2 => $DPM_INITIAL_CONF_1 . '
# Duplicated line
ALLOW_COREDUMP="no"
#
# Very similar line
ALLOW_COREDUMP2="no"
';

Readonly my $DPM_INITIAL_CONF_3 => $DPM_INITIAL_CONF_1 . '
#DISKFLAGS="a list of flag"
';

Readonly my $DMLITE_INITIAL_CONF_1 => '#
# This is the Apache configuration for the dmlite DAV.
#
# The first part of the file configures all the required options common to all
# VirtualHosts. The actual VirtualHost instances are defined at the end of this file.
#

# Static content
Alias /static/ /usr/share/lcgdm-dav/
<Location "/static">
  <IfModule expires_module>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
  </IfModule>
</Location>

# Alias for the delegation
ScriptAlias /gridsite-delegation "/usr/libexec/gridsite/cgi-bin/gridsite-delegation.cgi"

# Base path for nameserver requests
<LocationMatch "^/dpm/lal\.in2p3\.fr/.*">

  # None, one or several flags
  # Write      Enable write access
  # NoAuthn    Disables user authentication
  # RemoteCopy Enables third party copies
  NSFlags Write

  # On redirect, maximum number of replicas in the URL
  # (Used only by LFC)
  NSMaxReplicas 3

  # Redirection ports
  # Two parameters: unsecure (plain HTTP) and secure (HTTPS)
  # NSRedirectPort 80 443

  # List of trusted DN (as X509 Subject).
  # This DN can act on behalf of other users using the HTTP headers:
  # X-Auth-Dn
  # X-Auth-FqanN (Can be specified multiple times, with N starting on 0, and incrementing)
  # NSTrustedDNS "/DC=ch/DC=cern/OU=computers/CN=trusted-host.cern.ch"

  # If mod_gridsite does not give us information about the certificate, this
  # enables mod_ssl to pass environment variables that can be used by mod_lcgdm_ns
  # to get the user DN.
  SSLOptions +StdEnvVars

</LocationMatch>
';


Readonly my $DPM_EXPECTED_CONF_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
# should the dpm daemon run?
# any string but "yes" will equivalent to "NO"
#
RUN_DPMDAEMON="no"
#
# should we run with another limit on the number of file descriptors than the default?
# any string will be passed to ulimit -n
#ULIMIT_N=4096
#
###############################################################################################
# Change and uncomment the variables below if your setup is different than the one by default #
###############################################################################################

ALLOW_COREDUMP="yes"		# Line generated by Quattor

#################
# DPM variables #
#################

# - DPM Name Server host : please change !!!!!!
#DPNS_HOST=grid05.lal.in2p3.fr

# - make sure we use globus pthread model
export GLOBUS_THREAD_MODEL=pthread		# Line generated by Quattor
';

Readonly my $DPM_EXPECTED_CONF_2 => $DPM_EXPECTED_CONF_1 . '
# Duplicated line
ALLOW_COREDUMP="yes"		# Line generated by Quattor
#
# Very similar line
ALLOW_COREDUMP2="no"
';

Readonly my $DPM_EXPECTED_CONF_3 => $DPM_EXPECTED_CONF_1 . '
DISKFLAGS="Write RemoteCopy"		# Line generated by Quattor
';

Readonly my $DMLITE_EXPECTED_CONF_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#
# This is the Apache configuration for the dmlite DAV.
#
# The first part of the file configures all the required options common to all
# VirtualHosts. The actual VirtualHost instances are defined at the end of this file.
#

# Static content
Alias /static/ /usr/share/lcgdm-dav/
<Location "/static">
  <IfModule expires_module>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
  </IfModule>
</Location>

# Alias for the delegation
ScriptAlias /gridsite-delegation "/usr/libexec/gridsite/cgi-bin/gridsite-delegation.cgi"

# Base path for nameserver requests
<LocationMatch "^/dpm/lal\.in2p3\.fr/.*">

  # None, one or several flags
  # Write      Enable write access
  # NoAuthn    Disables user authentication
  # RemoteCopy Enables third party copies
NSFlags Write RemoteCopy

  # On redirect, maximum number of replicas in the URL
  # (Used only by LFC)
  NSMaxReplicas 3

  # Redirection ports
  # Two parameters: unsecure (plain HTTP) and secure (HTTPS)
  # NSRedirectPort 80 443

  # List of trusted DN (as X509 Subject).
  # This DN can act on behalf of other users using the HTTP headers:
  # X-Auth-Dn
  # X-Auth-FqanN (Can be specified multiple times, with N starting on 0, and incrementing)
  # NSTrustedDNS "/DC=ch/DC=cern/OU=computers/CN=trusted-host.cern.ch"

  # If mod_gridsite does not give us information about the certificate, this
  # enables mod_ssl to pass environment variables that can be used by mod_lcgdm_ns
  # to get the user DN.
  SSLOptions +StdEnvVars

</LocationMatch>
';

Readonly my $COND_TEST_INITIAL => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
NSFlags Write RemoteCopy
DiskFlags NoAuthn
';

Readonly my $COND_TEST_EXPECTED_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
NSFlags Write RemoteCopy
';

Readonly my $COND_TEST_EXPECTED_2 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
NSFlags Write RemoteCopy
#DiskFlags NoAuthn
';

Readonly my $COND_TEST_EXPECTED_3 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
DiskFlags NoAuthn
NSFlags Write RemoteCopy
';

Readonly my $NEG_COND_TEST_EXPECTED_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
DiskFlags NoAuthn
';

Readonly my $NEG_COND_TEST_EXPECTED_2 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#NSFlags Write RemoteCopy
DiskFlags NoAuthn
';


Readonly my $NO_RULE_EXPECTED => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
RFIO DAEMONV3_WRMT 1
';

Readonly my $MULTI_COND_SETS_EXPECTED => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
DPNS FTRUST node1.example.com
DPNS FTRUST node2.example.com
DPNS FTRUST node4.example.com
DPNS FTRUST node3.example.com
DPNS RTRUST node1.example.com node1.example.com node2.example.com node3.example.com node4.example.com
DPNS TRUST node1.example.com node2.example.com node4.example.com node3.example.com node1.example.com
DPNS WTRUST node1.example.com node2.example.com node3.example.com node4.example.com
';


Readonly my $XROOTD_INITIAL_1 => 'sec.protocol /usr/${xrdlibdir} unix
';

Readonly my $XROOTD_INITIAL_2 => 'dpm.listvoms
#dpm.nohv1
sec.protocol /usr/${xrdlibdir} unix
sec.protocol /usr/${xrdlibdir} gsi -crl 4 -key /etc/grid-security/dpmmgr/dpmkey.pem -md sha256:sha1
';

Readonly my $XROOTD_EXPECTED_0 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
dpm.nohv1
sec.protocol /usr/${xrdlibdir} gsi crl 3 key /etc/grid-security/dpmmgr/dpmkey.pem md sha256:sha1 vomsfun a_value
';

Readonly my $XROOTD_EXPECTED_1 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#sec.protocol /usr/${xrdlibdir} unix
dpm.nohv1
sec.protocol /usr/${xrdlibdir} gsi crl 3 key /etc/grid-security/dpmmgr/dpmkey.pem md sha256:sha1 vomsfun a_value
';

Readonly my $XROOTD_EXPECTED_2 => '# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor
#
#dpm.listvoms
dpm.nohv1
#sec.protocol /usr/${xrdlibdir} unix
sec.protocol /usr/${xrdlibdir} gsi -crl:3 -key:/etc/grid-security/dpmmgr/dpmkey.pem -md:sha256:sha1 -vomsfun:a_value
';


# Test rules

my %dpm_config_rules_1 = (
      "ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
     );

my %dpm_config_rules_2 = (
      "ALLOW_COREDUMP" => "allowCoreDump:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_BOOLEAN,
      "GLOBUS_THREAD_MODEL" => "globusThreadModel:dpm;".LINE_FORMAT_ENV_VAR,
      "DISKFLAGS" =>"DiskFlags:dpm;".LINE_FORMAT_SH_VAR.";".LINE_VALUE_ARRAY,
     );

my %dav_config_rules = (
        "NSFlags" =>"NSFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_with_conditions = (
        "NSFlags" =>"DiskFlags:dpm->NSFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" =>"DiskFlags:dpns->DiskFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_with_conditions_2 = (
        "NSFlags" =>"DiskFlags:dpm->NSFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" =>"DiskFlags:dpn->DiskFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_with_neg_conds = (
        "NSFlags" =>"!DiskFlags:dpm->NSFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" =>"!DiskFlags:dpns->DiskFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_no_rule = (
        "RFIO DAEMONV3_WRMT 1" => ";".LINE_FORMAT_KW_VAL,
);

my %rules_multi_cond_sets = (
        "DPNS TRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
        "DPNS WTRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY.":".LINE_VALUE_OPT_UNIQUE,
        "DPNS RTRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY.":".LINE_VALUE_OPT_SORTED,
        "DPNS FTRUST" => "dpm->hostlist:dpns,srmv1;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY.":".LINE_VALUE_OPT_SINGLE,
);

my %rules_always = (
        "NSFlags" => "ALWAYS->NSFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
        "DiskFlags" => "DiskFlags:dav;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_ARRAY,
);

my %rules_xrootd_1 = (
        'sec.protocol /usr/${xrdlibdir} unix' => "security/unix->unix:security;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_HASH,
        'sec.protocol /usr/${xrdlibdir} gsi' => "security/gsi->gsi:security;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_HASH,
        # Condition but empty value
        'dpm.listvoms' => "vomsat:security/gsi->;".LINE_FORMAT_KW_VAL,
        'dpm.nohv1' => "vomsfun:security/gsi->;".LINE_FORMAT_KW_VAL,
);

# Same as $rules_xrootd_1 with (LINE_KEY_OPT_PREFIX_DASH | LINE_VALUE_OPT_SEP_COLON) value option
my %rules_xrootd_2 = (
        'sec.protocol /usr/${xrdlibdir} unix' => "security/unix->unix:security;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_HASH.':'.(LINE_KEY_OPT_PREFIX_DASH | LINE_VALUE_OPT_SEP_COLON),
        'sec.protocol /usr/${xrdlibdir} gsi' => "security/gsi->gsi:security;".LINE_FORMAT_KW_VAL.";".LINE_VALUE_HASH.':'.(LINE_KEY_OPT_PREFIX_DASH | LINE_VALUE_OPT_SEP_COLON),
        # Condition but empty value
        'dpm.listvoms' => "vomsat:security/gsi->;".LINE_FORMAT_KW_VAL,
        'dpm.nohv1' => "vomsfun:security/gsi->;".LINE_FORMAT_KW_VAL,
);

# Option sets

my $dpm_options = {dpm => {allowCoreDump => 1,
                           globusThreadModel => "pthread",
                           fastThreads => 200,
                           DiskFlags => [ "Write", "RemoteCopy" ],
                          },
                   dpns => {hostlist => ['node1.example.com', 'node2.example.com']},
                   srmv1 => {hostlist => ['node4.example.com', 'node3.example.com', 'node1.example.com']}};

my $dmlite_options = {dav => {NSFlags => [ "Write", "RemoteCopy" ],
                              DiskFlags => [ "NoAuthn" ],
                             }};

my $xrootd_options = {security => {gsi => {crl => 3,
                                           key => '/etc/grid-security/dpmmgr/dpmkey.pem',
                                           md => 'sha256:sha1',
                                           vomsfun => 'a_value',
                                          },
                                  }};


my $all_options = {%$dpm_options, %$dmlite_options};


#########################################
# Function actually executing the tests #
#########################################

sub test_rule_parsing {
    my ($obj, $fn, $initial_data, $args, $expected, $test_info) = @_;
    
    set_file_contents($fn, $initial_data);
    my $fh = CAF::RuleBasedEditor->open($fn, log => $obj);
    ok(defined($fh), "$fn was opened $test_info");
    $fh->updateFile(@$args);
    is("$fh", $expected, "$fn has expected contents $test_info");
    my $changes = $fh->close();
    
    return $changes;    
}

#############
# Main code #
#############

$CAF::Object::NoAction = 1;
set_caf_file_close_diff(1);

my $obj = Test::Quattor::Object->new();

$SIG{__DIE__} = \&confess;


# Test  simple variable substitution
test_rule_parsing($obj, $DPM_CONF_FILE, $DPM_INITIAL_CONF_1, [\%dpm_config_rules_1, $dpm_options], $DPM_EXPECTED_CONF_1, "(config 1)");

# Test potentially ambiguous config (duplicated lines, similar keywords)
test_rule_parsing($obj, $DPM_CONF_FILE, $DPM_INITIAL_CONF_2, [\%dpm_config_rules_1, $dpm_options], $DPM_EXPECTED_CONF_2, "(config 2)");

# Test array displayed as list
test_rule_parsing($obj, $DPM_CONF_FILE, $DPM_INITIAL_CONF_3, [\%dpm_config_rules_2, $dpm_options], $DPM_EXPECTED_CONF_3, "(config 3)");

# Test 'keyword value" format (a la Apache)
test_rule_parsing($obj, $DMLITE_CONF_FILE, $DMLITE_INITIAL_CONF_1, [\%dav_config_rules, $dmlite_options], $DMLITE_EXPECTED_CONF_1, "");

# Test rule conditions
test_rule_parsing($obj, $DMLITE_CONF_FILE, '', [\%rules_with_conditions, $all_options], $COND_TEST_EXPECTED_1, "(rules with conditions)");
test_rule_parsing($obj, $DMLITE_CONF_FILE, '', [\%rules_with_neg_conds, $all_options], $NEG_COND_TEST_EXPECTED_1, "(rules with negative conditions)");
test_rule_parsing($obj, $DMLITE_CONF_FILE, $COND_TEST_INITIAL, [\%rules_with_conditions, $all_options], $COND_TEST_INITIAL,
                                                                    "(initial contents, rules conditions with non existent attribute)");
test_rule_parsing($obj, $DMLITE_CONF_FILE, $COND_TEST_INITIAL, [\%rules_with_conditions_2, $all_options], $COND_TEST_INITIAL,
                                                                    "(initial contents, rules conditions with non existent option set)");

my %parser_options;
$parser_options{remove_if_undef} = 1;
test_rule_parsing($obj, $DMLITE_CONF_FILE, $COND_TEST_INITIAL, [\%rules_with_conditions, $all_options, \%parser_options], $COND_TEST_EXPECTED_2,
                                                                    "(initial contents, rules conditions, parser options)");
test_rule_parsing($obj, $DMLITE_CONF_FILE, $COND_TEST_INITIAL, [\%rules_with_neg_conds, $all_options, \%parser_options], $NEG_COND_TEST_EXPECTED_2,
                                                                    "(initial contents, rules with negative conditions, parser options)");

test_rule_parsing($obj, $DMLITE_CONF_FILE, '', [\%rules_always, $dmlite_options], $COND_TEST_EXPECTED_3, "(always_rules_only not set)");
$parser_options{always_rules_only} = 1;
test_rule_parsing($obj, $DMLITE_CONF_FILE, '', [\%rules_always, $dmlite_options, \%parser_options], $COND_TEST_EXPECTED_1, "(always_rules_only set)");

# Rule with only a keyword
test_rule_parsing($obj, $DPM_SHIFT_CONF_FILE, '', [\%rules_no_rule, $dpm_options], $NO_RULE_EXPECTED, "(keyword only)");

# Rule with multiple condition sets and multiple-word keyword
test_rule_parsing($obj, $DPM_SHIFT_CONF_FILE, '', [\%rules_multi_cond_sets, $dpm_options], $MULTI_COND_SETS_EXPECTED, "(multiple condition sets)");

# Rules with hashes
$parser_options{remove_if_undef} = 1;
$parser_options{always_rules_only} = 0;
test_rule_parsing($obj, $XROOTD_CONF_FILE, '', [\%rules_xrootd_1, $xrootd_options, \%parser_options], $XROOTD_EXPECTED_0, "");
test_rule_parsing($obj, $XROOTD_CONF_FILE, $XROOTD_INITIAL_1, [\%rules_xrootd_1, $xrootd_options, \%parser_options], $XROOTD_EXPECTED_1, "(with initial contents)");
test_rule_parsing($obj, $XROOTD_CONF_FILE, $XROOTD_INITIAL_2, [\%rules_xrootd_2, $xrootd_options, \%parser_options], $XROOTD_EXPECTED_2, "(with initial contents 2)");


Test::NoWarnings::had_no_warnings();
