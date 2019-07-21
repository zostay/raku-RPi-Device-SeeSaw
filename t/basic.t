use v6;

use Test;

use RPi::Device::SeeSaw;
use RPi::Device::SeeSaw::Interface :ALL;
use RPi::Device::SeeSaw::Types :ALL;
use RPi::Device::SeeSaw::Interface::Test;

my $pin;
sub repin { $pin = floor(rand * 64) }

sub pin2bulk {
    my buf8 $buf .= new;
    $buf.write-uint64: 0, 1 +< $pin, BigEndian;
    @$buf;
}

sub value2bytes($v, $bits) {
    my $bytes = $bits div 8;
    do for ^$bytes -> $byte {
        my $shift-by = ($bytes - $byte - 1) * 8;
        ($v +> $shift-by) +& 0xFF
    }
}

my $got;

my $iface = RPi::Device::SeeSaw::Interface::Test.new,
my RPi::Device::SeeSaw $ss .= new(
    delegate => $iface,
);

ok $ss;

$ss.software-reset;
is-deeply $iface.output, buf8.new(Status-Base, Status-SwRst, 0xFF);
$iface.reset;

$ss.get-options;
is-deeply $iface.output, buf8.new(Status-Base, Status-Options);
$iface.reset;

$ss.get-version;
is-deeply $iface.output, buf8.new(Status-Base, Status-Version);
$iface.reset;

repin;
$ss.pin-mode($pin, Output);
is-deeply $iface.output, buf8.new(GPIO-Base, GPIO-DirSet-Bulk, pin2bulk);
$iface.reset;

repin;
$ss.pin-mode($pin, Input);
is-deeply $iface.output, buf8.new(GPIO-Base, GPIO-DirClr-Bulk, pin2bulk);
$iface.reset;

repin;
$ss.pin-mode($pin, InputPullup);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-DirClr-Bulk, pin2bulk,
    GPIO-Base, GPIO-PullEnSet, pin2bulk,
    GPIO-Base, GPIO-Bulk-Set, pin2bulk,
);
$iface.reset;

repin;
$ss.pin-mode($pin, InputPulldown);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-DirClr-Bulk, pin2bulk,
    GPIO-Base, GPIO-PullEnSet, pin2bulk,
    GPIO-Base, GPIO-Bulk-Clr, pin2bulk,
);
$iface.reset;

my $channel = $ss.pwm-pins.pick;
my $value = floor(rand * 65536);
$ss.analog-write($channel.key, $value);
is-deeply $iface.output, buf8.new(
    Timer-Base, Timer-PWM, $channel.value, value2bytes($value, 16),
);
$iface.reset;

done-testing;
