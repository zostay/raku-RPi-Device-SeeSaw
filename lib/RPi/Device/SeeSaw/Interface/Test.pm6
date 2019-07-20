use v6;

use RPi::Device::SeeSaw::Types :ALL;
use RPi::Device::SeeSaw::Interface :ALL;

unit class RPi::Device::SeeSaw::Interface::Test does RPi::Device::SeeSaw::Interface;

has buf8 $.input;
has buf8 $.output;

method do-read(I2CReadLength:D $length --> blob8:D) {
    $.output.subbuf-rw(0, $length) = blob8.new;
}

method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf) {
    $.input.append: $buf;
}
