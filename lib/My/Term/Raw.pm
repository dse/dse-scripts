package My::Term::Raw;
use warnings;
use strict;
use POSIX;
use Term::ReadKey;

use base "Exporter";
our @EXPORT = qw();
our @EXPORT_OK = qw(enable_raw_mode
                    disable_raw_mode);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $termios;
our $orig_cflag;
our $orig_iflag;
our $orig_lflag;
our $orig_oflag;
our $orig_vmin;
our $orig_vtime;
our $raw_cflag;
our $raw_iflag;
our $raw_lflag;
our $raw_oflag;
our $raw_vmin;
our $raw_vtime;

our $is_raw = 0;
our $wants_raw = 0;

our $termios_orig;
our $termios_raw;

sub save_orig {
    if (!defined $termios_orig) {
        $termios_orig = POSIX::Termios->new();
        $termios_orig->getattr(STDIN_FILENO);
    }
    if (!defined $termios_raw) {
        $termios_raw = POSIX::Termios->new();
        $termios_raw->getattr(STDIN_FILENO);
        $termios_raw->setcflag($termios_raw->getcflag | (CS8));
        # enables 8-bit character size mask
        $termios_raw->setiflag($termios_raw->getiflag & ~(BRKINT|ICRNL|INPCK|ISTRIP|IXON));
        # BRKINT don't flush input and output queues on BREAK
        # ICRNL  don't s/\r/\n/ on input
        # INPCK  disable parity checking
        # ISTRIP don't strip off 8th bit
        # IXON   disable XON/XOFF flow control
        $termios_raw->setlflag($termios_raw->getlflag & ~(ECHO|ICANON|IEXTEN|ISIG));
        # don't echo input characters
        # disable line-by-line input mode
        # disable impl-defined input processing
        # disable INTR, QUIT, SUSP, or DSUSP signals
        $termios_raw->setoflag($termios_raw->getoflag & ~(OPOST));
        # disable impl-defined output processing
        $termios_raw->setcc(VMIN, 0);
        # minimum number of characters for non-canonical read
        $termios_raw->setcc(VTIME, 1);
        # timeout in deciseconds
    }
}

sub enable_raw_mode {
    save_orig();
    $is_raw = 1;
    $termios_raw->setattr(STDIN_FILENO, TCSAFLUSH);
}

sub disable_raw_mode {
    $is_raw = 0;
    if (defined $termios_orig) {
        $termios_orig->setattr(STDIN_FILENO, TCSAFLUSH);
    }
}

sub save_raw_mode_state {
    $wants_raw = $is_raw;
    disable_raw_mode();
}

sub restore_raw_mode_state {
    if ($wants_raw) {
        enable_raw_mode();
    }
}

END {
    disable_raw_mode() if $is_raw;
}

BEGIN {
    $SIG{ABRT} = sub { disable_raw_mode(); };
    $SIG{HUP}  = sub { disable_raw_mode(); };
    $SIG{INT}  = sub { disable_raw_mode(); };
    $SIG{KILL} = sub { disable_raw_mode(); };
    $SIG{QUIT} = sub { disable_raw_mode(); };
    $SIG{STOP} = sub { save_raw_mode_state(); };
    $SIG{CONT} = sub { restore_raw_mode_state(); };
    $SIG{TSTP} = sub { disable_raw_mode(); };
    $SIG{TERM} = sub { disable_raw_mode(); };
}

1;
