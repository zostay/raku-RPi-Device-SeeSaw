use v6;

use RPi::Device::SeeSaw::Interface :ALL;
use RPi::Device::SeeSaw::Types :ALL;

unit package RPi::Device::SeeSaw::Keypad;

class KeyEventRaw {
    has KeypadEdge $.edge;
    has UByte $.number;

    multi method new(UByte:D $register --> KeyEventRaw:D) {
        self.bless:
            edge   => $register +& 0x03,
            number => $register +> 2,
            ;
    }
}

class KeyEvent {
    has KeypadEdge $.edge;
    has UShort $.number;

    multi method new(UShort:D $register --> KeyEventRaw:D) {
        self.bless:
            edge   => $register +& 0x03,
            number => $register +> 2,
            ;
    }
}

class KeyState {
    has KeypadEdge $.edge is required;
    has Bool $.active is required;

    method register(--> UByte:D) { 1 +< ($.edge + 1) +| $.active }
}

