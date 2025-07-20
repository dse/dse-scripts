package My::Color::Functions;
use warnings;
use strict;

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(lum);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub lum {
    if (scalar @_ == 1) {
        my ($x) = @_;
        if (ref $x eq '') {
            $x = clamp($x, 0, 1);
            if ($x <= 0.03928) {
                return $x / 12.92;
            }
            return (($x + 0.055) / 1.055) ** 2.4;
        }
        if (ref $x eq 'ARRAY' && all { ref $_ eq '' } @$x) {
            if (scalar @$x == 3) {
                return lum(@$x);
            }
        }
    }
    if (scalar @_ == 3 && all { ref $_ eq '' } @_) {
        my ($r, $g, $b) = map { clamp($_, 0, 1) } @_;
        return 0.2126 * lum($r) + 0.7152 * lum($g) + 0.0722 * lum($b);
    }
    die("lum: invalid arguments\n");
}

1;
