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

my $bulk;
sub rebulk { $bulk = floor(rand * 0xFFFF_FFFF_FFFF_FFFF) }

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

repin;
$ss.digital-write($pin, True);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-Bulk-Set, pin2bulk,
);
$iface.reset;

repin;
$ss.digital-write($pin, False);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-Bulk-Clr, pin2bulk,
);
$iface.reset;

rebulk;
$ss.digital-write-bulk($bulk, True);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-Bulk-Set, value2bytes($bulk, 64)
);
$iface.reset;

rebulk;
$ss.digital-write-bulk($bulk, False);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-Bulk-Clr, value2bytes($bulk, 64)
);
$iface.reset;

repin;
$ss.digital-read($pin);
is-deeply $iface.output, buf8.new(GPIO-Base, GPIO-Bulk);
$iface.reset;

$ss.digital-read-bulk;
is-deeply $iface.output, buf8.new(GPIO-Base, GPIO-Bulk);
$iface.reset;

rebulk;
$ss.set-gpio-interrupts($bulk, True);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-IntEnSet, value2bytes($bulk, 64)
);
$iface.reset;

rebulk;
$ss.set-gpio-interrupts($bulk, False);
is-deeply $iface.output, buf8.new(
    GPIO-Base, GPIO-IntEnClr, value2bytes($bulk, 64)
);
$iface.reset;

$channel = $ss.adc-pins.pick;
$ss.analog-read($channel.key);
is-deeply $iface.output, buf8.new(
    ADC-Base,
    ADC-Channel-Offset + $channel.value,
);
$iface.reset;

$channel = $ss.pwm-pins.pick;
$value = floor(rand * 65536);
$ss.set-pwm-frequency($channel.key, $value);
is-deeply $iface.output, buf8.new(
    Timer-Base, Timer-Freq, value2bytes($value, 16)
);
$iface.reset;

$channel = floor(rand * 4);
$ss.enable-sercom-data-ready-interrupt($channel);
is-deeply $iface.output, buf8.new(
    SerCom0-Base + $channel, SerCom-IntEn, 1,
);
$iface.reset;

$channel = floor(rand * 4);
$ss.disable-sercom-data-ready-interrupt($channel);
is-deeply $iface.output, buf8.new(
    SerCom0-Base + $channel, SerCom-IntEn, 0,
);
$iface.reset;

$channel = floor(rand * 4);
$ss.read-sercom-data($channel);
is-deeply $iface.output, buf8.new(
    SerCom0-Base + $channel, SerCom-Data;
);
$iface.reset;

my $addr = floor(rand * 64);
$value = floor(rand * 256);
$ss.eeprom-write($addr, $value);
is-deeply $iface.output, buf8.new(
    EEPROM-Base, $addr, $value
);
$iface.reset;

$addr = floor(rand * 64);
$ss.eeprom-read($addr);
is-deeply $iface.output, buf8.new(
    EEPROM-Base, $addr,
);
$iface.reset;

done-testing;
