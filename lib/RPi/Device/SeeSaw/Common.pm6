use v6;

use RPi::Device::SeeSaw::Interface :ALL;
use RPi::Device::SeeSaw::Interface::Delegate;
use RPi::Device::SeeSaw::Types :ALL;
use RPi::Device::SeeSaw::Keypad;

unit role RPi::Device::SeeSaw::Common does RPi::Device::SeeSaw::Interface::Delegate;

my constant CRICKIT-PID    = 9999;
my constant ROBOHATMM1-PID = 9998;

method adc-pins(--> Hash[Int, Int]) { ... }
method pwm-pins(--> Hash[Int, Int]) { ... }
method touch-pins(--> Hash[Int, Int]) { ... }

method software-reset() {
    self.write: Status-Base, Status-SwRst, blob8.new(0xFF);
}

method get-options(--> ULong:D) {
    self.read-uint32: Status-Base, Status-Options;
}

method get-version(--> ULong:D) {
    self.read-uint32: Status-Base, Status-Version;
}

multi method pin-mode(PinNumber:D $pin, PinMode:D() $mode) {
    self.pin-mode-bulk(1 +< $pin, $mode);
}

multi method pin-mode-bulk(0, $) { }
multi method pin-mode-bulk(
    PinBitset:D $pins,
    PinMode:D() $mode,
) {
    given $mode {
        when Output {
            self.write-uint64: GPIO-Base, GPIO-DirSet-Bulk, $pins;
        }
        when Input {
            self.write-uint64: GPIO-Base, GPIO-DirClr-Bulk, $pins;
        }
        when InputPullup {
            self.write-uint64: GPIO-Base, GPIO-DirClr-Bulk, $pins;
            self.write-uint64: GPIO-Base, GPIO-PullEnSet, $pins;
            self.write-uint64: GPIO-Base, GPIO-Bulk-Set, $pins;
        }
        when InputPulldown {
            self.write-uint64: GPIO-Base, GPIO-DirClr-Bulk, $pins;
            self.write-uint64: GPIO-Base, GPIO-PullEnSet, $pins;
            self.write-uint64: GPIO-Base, GPIO-Bulk-Clr, $pins;
        }
        default {
            die "Invalid pin mode";
        }
    }
}

multi method analog-write(PinNumber:D $pin, UShort:D $value) {
    with $.pwm-pins.{ $pin } -> $offset {
        my buf8 $cmd .= new($offset);
        $cmd.write-uint16: 1, $value, BigEndian;
        self.write: Timer-Base, Timer-PWM, $cmd;
    }
    else {
        die "Invalid PWM pin";
    }
}

multi method digital-write(PinNumber:D $pin, Bool:D() $value) {
    self.digital-write-bulk(1 +< $pin, $value);
}

multi method digital-write-bulk(
    PinBitset:D $pins,
    Bool:D() $value,
) {
    my $op = $value ?? GPIO-Bulk-Set !! GPIO-Bulk-Clr;
    self.write-uint64: GPIO-Base, $op, $pins;
}

method digital-read(PinNumber:D $pin --> Bool:D) {
    self.digital-read-bulk +& (1 +< $pin) != 0;
}

multi method digital-read-bulk(--> PinBitset:D) {
    self.read-uint64: GPIO-Base, GPIO-Bulk;
}

method set-gpio-interrupts(PinBitset:D $pins, Bool:D() $enabled) {
    self.write-uint64:
        GPIO-Base,
        $enabled ?? GPIO-IntEnSet !! GPIO-IntEnClr,
        $pins,
        ;
}

method analog-read(PinNumber:D $pin --> UShort:D) {
    die "Invalid ADC pin"
        without $.adc-pins.{ $pin };

    self.read-uint16:
        ADC-Base,
        ADC-Channel-Offset + $.adc-pins.{ $pin },
        ;
}

method touch-read(PinNumber:D $pin --> UShort:D) {
    die "Invalid touch pin"
        without $.touch-pins.{ $pin };

    self.read-uint16:
        Touch-Base,
        Touch-Channel-Offset + $.touch-pins.{ $pin },
        ;
}

method set-pwm-frequency(PinNumber:D $pin, UShort:D $value) {
    with $.pwm-pins.{ $pin } -> $offset {
        self.write-uint16: Timer-Base, Timer-PWM, $value;
        sleep 0.001;
    }
    else {
        die "Invalid PWM pin";
    }
}

method enable-sercom-data-ready-interrupt(UByte:D $sercom = 0) {
    self.write-uint8: SerCom0-Base + $sercom, SerCom-IntEn, 1;
}

method disable-sercom-data-ready-interrupt(UByte:D $sercom = 0) {
    self.write-uint8: SerCom0-Base + $sercom, SerCom-IntEn, 0;
}

method read-sercome-data(UByte:D $sercom = 0 --> UByte:D) {
    self.read-uint8: SerCom0-Base + $sercom, SerCom-Data;
}

multi method eeprom-write(UByte:D $addr, UByte:D $value) {
    self.eeprom-write: $addr, blob8.new($value);
}

multi method eeprom-write(UByte:D $addr, blob8:D $buf) {
    self.write: EEPROM-Base, $addr, $buf;
}

method eeprom-read(UByte:D $addr --> UByte:D) {
    self.read-uint8: EEPROM-Base, $addr;
}

# method set-i2c-address(UByte:D $address) {
#     self.eeprom-write: EEPROM-I2C-Addr, $address;
#     sleep(0.250);
#     $!i2c-bus .= new(device => $i2c-device, address => $i2c-address);
#     self.software-reset;
# }
#
# method get-i2c-address(--> UByte:D) {
#     self.eeprom-read: EEPROM-I2C-Addr;
# }

method set-uart-baud(ULong:D $baud) {
    self.write-uint32: SerCom0-Base, SerCom-Baud, $baud;
}

method set-keypad-event(UByte:D $key, KeypadEdge:D $edge, Bool:D $active) {
    my RPi::Device::SeeSaw::Keypad::KeyState $ks .= new(:$edge, :$active);
    self.write: Keypad-Base, Keypad-Event, blob8.new($key, $ks.register);
}

method enable-keypad-interrupt() {
    self.write-uint8: Keypad-Base, Keypad-IntEnSet, 1;
}

method disable-keypad-interrupt() {
    self.write-uint8: Keypad-Base, Keypad-IntEnClr, 1;
}

method get-keypad-count(--> UByte:D) {
    self.read-uint8: Keypad-Base, Keypad-Count, .:delay(.0005);
}

method read-keypad(UByte:D $count --> Seq:D) {
    self.read(Keypad-Base, Keypad-FIFO, $count).map({
        RPi::Device::SeeSaw::Keypad::KeyEventRaw.new($_)
    }, :delay(.001));
}

method get-temperature(--> UShortRat:D) {
    my $value = self.read-uint32(Status-Base, Status-Temp, :delay(.001));
    $value / 65536;
}

method get-encoder-position(--> Long:D) {
    self.read-int32: Encoder-Base, Encoder-Position;
}

method get-encoder-delta(--> Long:D) {
    self.read-int32: Encoder-Base, Encoder-Delta;
}

method set-encoder-position(Long:D $pos) {
    self.write-int32: Encoder-Base, Encoder-Position, $pos;
}

method enable-encoder-interrupt() {
    self.write-uint8: Encoder-Base, Encoder-IntEnSet, 1;
}

method disable-encoder-interrupt() {
    self.write-uint8: Encoder-Base, Encoder-IntEnClr, 1;
}

=begin pod

=head1 NAME

RPi::Device::SeeSaw::Common - common tools for use with the various Adafruit SeeSaw modules

=head1 DESCRIPTION

Provides an unconfigured, mid-level interface to work with the pins of SeeSaw microcontroller modules. This includes modules like the SeeSaw, NeoTrellis, Crickit, and various other hats they sell.

=head1 ROLES

This role also implements L<RPi::Device::SeeSaw::Interface>, which defines the low-level routines required for communicating with SeeSaw firmware.

=head1 REQUIRED METHODS

=head2 method adc-pins

    method adc-pins(--> Hash[Int, Int])

This method must return a map of port pin numbers to channel numbers for the Analog-to-Digital pins used for C<analog-read> operations.

=head2 method pwm-pins

    method pwm-pins(--> Hash[Int, Int])

This method must return a map of port pin numbers to channel numbers for the Pulse-Width-Modulation pins used for C<analog-write> operations.

=head1 METHODS

For full documention of these methods, see L<RPi::Device::SeeSaw> which holds that documentation in a central location.

=end pod
