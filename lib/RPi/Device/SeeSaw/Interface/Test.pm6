use v6;

use RPi::Device::SeeSaw::Types :ALL;
use RPi::Device::SeeSaw::Interface :ALL;

unit class RPi::Device::SeeSaw::Interface::Test does RPi::Device::SeeSaw::Interface;

has buf8 $.input .= new;
has buf8 $.output .= new;

method reset() {
    $.input .= new;
    $.output .= new;
}

method do-read(I2CReadLength:D $length --> blob8:D) {
    $.input.append: 0 while $length > $.input.elems;
    $.input.subbuf-rw(0, $length) = blob8.new;
}

method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf) {
    $.output.append: $reg-base, $reg;
    $.output.append: $buf;
}
