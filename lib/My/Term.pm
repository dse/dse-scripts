package My::Term;
use warnings;
use strict;
use File::Basename qw(dirname);

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(term_query);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use lib sprintf("%s/../../lib", dirname(__FILE__));
use My::Term::Raw qw(enable_raw_mode
                     disable_raw_mode);

sub term_query {
    my %args = @_;
    my ($prompt, $query, $max, $chop) = @args{qw(prompt query max chop)};
    if (defined $prompt && length($prompt)) {
        STDOUT->print($prompt);
        STDOUT->flush();
    }
    STDOUT->print($query);
    STDOUT->flush();
    my $response;
    read(STDIN, $response, $max // 256);
    if (defined $chop && length($chop) && substr($response, 0 - length($chop)) eq $chop) {
        $response = substr($response, 0, 0 - length($chop))
    }
    return $response;
}

1;
