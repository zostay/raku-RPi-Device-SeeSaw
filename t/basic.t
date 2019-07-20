use v6;

use Test;

use RPi::Device::SeeSaw;
use RPi::Device::SeeSaw::Interface :ALL;
use RPi::Device::SeeSaw::Interface::Test;

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

done-testing;
