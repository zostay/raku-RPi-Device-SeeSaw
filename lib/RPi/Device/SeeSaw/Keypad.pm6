use v6;

unit package RPi::Device::SeeSaw::Keypad;

class KeyEventRaw {
    has KeyPadEdge $.edge;
    has UByte $.number;

    multi method new(UByte:D $register --> KeyEvent:D) {
        self.bless:
            edge   => $register +& 0x03,
            number => $register +> 2,
            ;
    }
}

class KeyEvent {
    has KeyPadEdge $.edge;
    has UShort $.number;

    multi method new(UShort:D $register --> KeyEventRaw:D) {
        self.bless:
            edge   => $register +& 0x03,
            number => $register +> 2,
            ;
    }
}

class KeyState {
    has KeyPadEdge $.edge is required;
    has Bool $.active is required;

    method register(--> UByte:D) { 1 +< ($.edge + 1) +| $.active }
}

