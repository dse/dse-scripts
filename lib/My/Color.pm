package My::Color;
use warnings;
use strict;
use POSIX qw(round);

sub new {
    my ($class, @args) = @_;
    if (scalar @args == 1) {
        my ($r, $g, $b, $a) = parse_color_string($args[0]);
        $a //= 1;
        my $self = bless({ r => $r, g => $g, b => $b, a => $a }, $class);
        return $self;
    }
    if (scalar @args == 3) {
        my ($r, $g, $b) = map { clamp($_, 0, 1) } @args;
        my $self = bless({ r => $r, g => $g, b => $b, a => 1 }, $class);
        return $self;
    }
    if (scalar @args == 4) {
        my ($r, $g, $b, $a) = map { clamp($_, 0, 1) } @args;
        my $self = bless({ r => $r, g => $g, b => $b, a => $a }, $class);
        return $self;
    }
    die("invalid arguments\n");
}

sub mix {
    my ($self, $other, $amt) = @_;
    $amt //= 0.5;
    my $r = $self->{r} + $amt * ($other->{r} - $self->{r});
    my $g = $self->{g} + $amt * ($other->{g} - $self->{g});
    my $b = $self->{b} + $amt * ($other->{b} - $self->{b});
    return __PACKAGE__->new($r, $g, $b);
}

sub to_string {
    my ($self, $type) = @_;
    return $self->to_255_string() if defined $type && $type eq '255';
    return $self->to_rgb_string() if defined $type && $type eq 'rgb';
    return $self->to_hex_string();
}

sub to_hex_string {
    my ($self) = @_;
    my $r = round($self->{r} * 255);
    my $g = round($self->{g} * 255);
    my $b = round($self->{b} * 255);
    my $a = round($self->{a} * 255);
    if ($a == 255) {
        return sprintf("#%02x%02x%02x", $r, $g, $b);
    }
    return sprintf("#%02x%02x%02x%02x", $r, $g, $b, $a);
}

sub to_rgb_string {
    my ($self) = @_;
    my $r = round($self->{r} * 255);
    my $g = round($self->{g} * 255);
    my $b = round($self->{b} * 255);
    my $a = round($self->{a} * 255);
    if (round($a * 255) < 255) {
        return sprintf("rgb(%d,%d,%d)", $r, $g, $b);
    }
    return sprintf("rgb(%d,%d,%d,%.1f%%)", $r, $g, $b, $self->{a});
}

sub to_255_string {
    my ($self) = @_;
    my $r = round($self->{r} * 255);
    my $g = round($self->{g} * 255);
    my $b = round($self->{b} * 255);
    my $a = round($self->{a} * 255);
    if ($a == 255) {
        return sprintf("%d,%d,%d", $r, $g, $b);
    }
    return sprintf("%d,%d,%d,%d", $r, $g, $b, $a);
}

sub to_rgb_255_string {
    my ($self) = @_;
    my $r = round($self->{r} * 255);
    my $g = round($self->{g} * 255);
    my $b = round($self->{b} * 255);
    my $a = round($self->{a} * 255);
    if ($a == 255) {
        return sprintf("%d,%d,%d", $r, $g, $b);
    }
    return sprintf("%d,%d,%d,%d", $r, $g, $b, $a);
}

sub contrast {
    my ($self, $other) = @_;
    return _contrast($self->lum(), $other->lum());
}

sub lum {
    my ($self) = @_;
    my $R = _lum($self->{r});
    my $G = _lum($self->{g});
    my $B = _lum($self->{b});
    return 0.2126 * $R + 0.7152 * $G + 0.0722 * $B;
}

sub _lum {
    my ($x) = @_;
    $x = clamp($x, 0, 1);
    if ($x <= 0.03928) {
        return $x / 12.92;
    }
    return (($x + 0.055) / 1.055) ** 2.4;
}

sub _contrast {
    my ($min, $max) = @_;
    if ($min > $max) {
        ($min, $max) = ($max, $min);
    }
    return ($max + 0.05) / ($min + 0.05);
}

sub parse_color_string {
    my ($str) = @_;
    return if !defined $str;
    if ($str =~ m{^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$} ||
        $str =~ m{^(?:rgba?:)?([0-9A-Fa-f]{2})\/([0-9A-Fa-f]{2})\/([0-9A-Fa-f]{2})$/}i) {
        my $r = hex($1)/255;
        my $g = hex($2)/255;
        my $b = hex($3)/255;
        return ($r, $g, $b, 1) if wantarray;
        return [$r, $g, $b, 1];
    }
    if ($str =~ m{^#?([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$} ||
        $str =~ m{^(?:rgba?:)?([0-9A-Fa-f]{2})\/([0-9A-Fa-f]{2})\/([0-9A-Fa-f]{2})\/([0-9A-Fa-f]{2})$/}i) {
        my $r = hex($1)/255;
        my $g = hex($2)/255;
        my $b = hex($3)/255;
        my $a = hex($4)/255;
        return ($r, $g, $b, $a) if wantarray;
        return [$r, $g, $b, $a];
    }
    if ($str =~ m{^([0-9]+),([0-9]+),([0-9]+)$}) {
        my $r = 0 + $1;
        my $g = 0 + $2;
        my $b = 0 + $3;
        $r = clamp($r, 0, 255) / 255;
        $g = clamp($g, 0, 255) / 255;
        $b = clamp($b, 0, 255) / 255;
        return ($r, $g, $b, 1) if wantarray;
        return [$r, $g, $b, 1];
    }
    if ($str =~ m{^([0-9]+),([0-9]+),([0-9]+),([0-9]+)$}) {
        my $r = 0 + $1;
        my $g = 0 + $2;
        my $b = 0 + $3;
        my $a = 0 + $4;
        $r = clamp($r, 0, 255) / 255;
        $g = clamp($g, 0, 255) / 255;
        $b = clamp($b, 0, 255) / 255;
        $a = clamp($a, 0, 255) / 255;
        return ($r, $g, $b, $a) if wantarray;
        return [$r, $g, $b, $a];
    }
    die("invalid color string: $str\n");
}

sub clamp {
    my ($x, $low, $high) = @_;
    return $x < $low ? $low : $x > $high ? $high : $x;
}

1;
