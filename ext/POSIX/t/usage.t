#!./perl -w

use strict;
use Test::More;
use Config;

plan(skip_all => "POSIX is unavailable")
    unless $Config{extensions} =~ /\bPOSIX\b/;

require POSIX;

my %valid;
my @all;

my $argc = 0;
for my $list ([qw(errno fork getchar getegid geteuid getgid getgroups getlogin
		  getpgrp getpid getppid gets getuid time wait)],
	      [qw(abs alarm assert chdir closedir cos exit exp fabs fstat getc
		  getenv getgrgid getgrnam getpwnam getpwuid gmtime isatty
		  localtime log opendir raise readdir remove rewind rewinddir
		  rmdir sin sleep sqrt stat strerror system
		  umask unlink)],
	      [qw(atan2 chmod creat kill link mkdir pow rename strstr waitpid)],
	      [qw(chown fcntl utime)]) {
    $valid{$_} = $argc foreach @$list;
    push @all, @$list;
    ++$argc;
}

my @try = 0 .. $argc - 1;
foreach my $func (sort @all) {
    my $arg_pat = join ', ', ('[a-z]+') x $valid{$func};
    my $expect = qr/\AUsage: POSIX::$func\($arg_pat\) at \(eval/;
    foreach my $try (@try) {
	next if $valid{$func} == $try;
	my $call = "POSIX::$func(" . join(', ', 1 .. $try) . ')';
	is(eval "$call; 1", undef, "$call fails");
	like($@, $expect, "POSIX::$func for $try arguments gives expected error")
    }
}

foreach my $func (qw(printf sprintf)) {
    is(eval "POSIX::$func(); 1", undef, "POSIX::$func() fails");
    like($@, qr/\AUsage: POSIX::$func\(pattern, args\.\.\.\) at \(eval/,
	 "POSIX::$func for 0 arguments gives expected error");
}

# Tests which demonstrate that, where the POSIX.pod documentation claims that
# the POSIX function performs the same as the equivalent builtin function,
# that is actually so (assuming that the POSIX::* function is provided an
# explicit argument).

my $val;

{
    # abs
    $val = -3;
    is(abs($val), POSIX::abs($val),
        'abs() and POSIX::abs() match when each is provided with an explicit value');
}

{
    # alarm
    my ($start_time, $end_time, $core_msg, $posix_msg);

    $val = 2;
    local $@;
    eval {
        local $SIG{ALRM} = sub { $end_time = time; die "ALARM!\n" };
        $start_time = time;
        alarm $val;

        # perlfunc recommends against using sleep in combination with alarm.
        1 while (($end_time = time) - $start_time < 6);
        alarm 0;
    };
    alarm 0;
    $core_msg = $@;

    local $@;
    eval {
        local $SIG{ALRM} = sub { $end_time = time; die "ALARM!\n" };
        $start_time = time;
        POSIX::alarm($val);

        # perlfunc recommends against using sleep in combination with POSIX::alarm.
        1 while (($end_time = time) - $start_time < 6);
        POSIX::alarm(0);
    };
    POSIX::alarm(0);
    $posix_msg = $@;

    is($posix_msg, $core_msg,
        "alarm() and POSIX::alarm() match when each is provided with an explicit value");
}

{
    # atan2
    my ($y, $x) = (3, 1);
    is(POSIX::atan2($y, $x), atan2($y, $x),
        "atan2() and POSIX::atan2() match; need 2 args");
}

{
    # chdir
    require File::Spec;

    my $curdir = File::Spec->curdir();
    my $tdir = File::Spec->tmpdir();

    my ($coredir, $posixdir);

    chdir($tdir) or die "Unable to change to a different starting directory";
    chdir($curdir);
    $coredir = File::Spec->curdir();

    chdir($tdir) or die "Unable to change to a different starting directory";
    POSIX::chdir($curdir);
    $posixdir = File::Spec->curdir();

    is($posixdir, $coredir,
        "chdir() and POSIX::chdir() match when each is provided with an explicit value");
}

{
	# localtime
    my (@lt, @plt);

    $val = 300_000;
    @lt = localtime($val);
    @plt = POSIX::localtime($val);
    is_deeply(\@plt, \@lt,
	    'localtime() and POSIX::localtime() match when each is provided explicit value');
}

done_testing();
