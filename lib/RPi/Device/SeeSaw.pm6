use v6;

use RPi::Device::SMBus;
use RPi::Device::SeeSaw::DigitalIO;
use RPi::Device::SeeSaw::PinMap :all;
use RPi::Device::SeeSaw::Types :short-names;

unit class RPi::Device::SeeSaw does RPi::Device::SeeSaw::Common;

enum (
    ADC-Input0-Pin => 2,
    ADC-Input1-Pin => 3,
    ADC-Input2-Pin => 4,
    ADC-Input3-Pin => 5,
);

my constant Int %ADC-PINS{Int} =
    ADC-Input0-Pin, 0,
    ADC-Input1-Pin, 1,
    ADC-Input2-Pin, 2,
    ADC-Input3-Pin, 3,
    ;

enum (
    PWM0-Pin => 4,
    PWM1-Pin => 5,
    PWM2-Pin => 6,
    PWM3-Pin => 6,
);

my constant Int %PWM-PINS{Int} =
    PWM0-Pin, 0,
    PWM1-Pin, 1,
    PWM2-Pin, 2,
    PWM3-Pin, 3,
    ;


method get-digital-pin(PinNumber:D $pin --> Bool:D() $value) {
    my ($bank, $bulk) = self!pin-to-bulk($pin);
    self.digital-read-bulk($bulk, :$bank) != 0;
}

method !bank-select($bitset, $bank) {
    my buf8 $buf .= new;
    if $bank eq 'A' {
        $buf.write-uint32(0, $bitset, BigEndian);
    }
    else {
        $buf.write-uint64(0, $bitset, BigEndian);
    }
    $buf;
}

method !double-bank($bits-a, $bits-b) {
    my buf8 $buf .= new;
    $buf.write-uint32(0, $bits-a, BigEndian);
    $buf.write-uint32(4, $bits-b, BigEndian);
    $buf;
}

method get-digital-pins(PinBitset:D $pins, PinBank:D :$bank = 'A' --> PinBitset:D) {
    self!read32:
        GPIO-BASE,
        GPIO-BULK,
        self!bank-select($pins, $bank),
        ;
}

method set-gpio-interrupts(PinBitset:D $pins, Bool:D() $enabled) {
    self!write:
        GPIO-BASE,
        $enabled ?? GPIO-INTENSET !! GPIO-INTENCLR,
        self!bank-select($pins, 'A'),
        ;
}

method get-analog-pin(PinNumber:D $pin --> UShort:D) {
    die "Invalid ADC pin"
        without $!pin-mapping.analog-pins.{ $pin };

    self!read16:
        ADC-BASE,
        ADC-CHANNEL-OFFSET + $!pin-mapping.analog-pins.{ $pin },
        ;
}

method get-touch-pin(PinNumber:D $pin --> UShort:D) {
    die "Invalid touch pin"
        without $!pin-mapping.touch-pins.{ $pin };

    self!read16:
        TOUCH-BASE,
        TOUCH-CHANNEL-OFFSET + $!pin-mapping.touch-pins.{ $pin },
        ;
}

multi method set-pins-mode(
    PinBitset:D $pins,
    PinMode:D() $mode,
    PinBank:D :$bank = 'A',
) {
    if $bank eq 'A' {
        self.set-pins-mode($pins, 0, $mode);
    }
    else {
        self.set-pins-mode(0, $pins, $mode);
    }
}

multi method set-pins-mode(
    PinBitset:D $pins-a,
    PinBitset:D $pins-b,
    PinMode:D() $mode,
) {
    my $cmd = self!boudl-bank($pins-a, $pins-b);
    given $mode {
        when Output {
            self!write: GPIO-BASE, GPIO-DIRSET-BULK, $cmd;
        }
        when Input {
            self!write: GPIO-BASE, GPIO-DIRCLR-BULK, $cmd;
        }
        when InputPullup {
            self!write: GPIO-BASE, GPIO-DIRCLR-BULK, $cmd;
            self!write: GPIO-BASE, GPIO-PULLENSET, $cmd;
            self!write: GPIO-BASE, GPIO-BULK-SET, $cmd;
        }
        when InputPulldown {
            self!write: GPIO-BASE, GPIO-DIRCLR-BULK, $cmd;
            self!write: GPIO-BASE, GPIO-PULLENSET, $cmd;
            self!write: GPIO-BASE, GPIO-BULK-CLR, $cmd;
        }
        default {
            die "Invalid pin mode";
        }
    }
}

method set-digital-pins(
    PinBitset:D $pins,
    Bool:D() $value,
    PinBank:D :$bank = 'A',
) {
    my $op = $value ?? GPIO-BULK-SET !! GPIO-BULK-CLR;
    self!write:
        GPIO-BASE,
        $op,
        self!pin-to-bulk($pins, $bank),
        ;
}

method set-pwm-frequency(PinNumber:D $pin, UShort:D $value) {
    with $!pin-mapping.pwm-pins.{ $pin } -> $offset {
        if $!pin-mapping.pwm-width == 16 {
            $cmd = buf8.new($offset, $value +> 8, $value +& 0xFF);
        }
        elsif $value ~~ UByte {
            $cmd = buf8.new($offset, $value);
        }
        else {
            die "Invalid value for 8-bit PWM";
        }

        self!write: TIMER-BASE, TIMER-PWM, $cmd;
        sleep 0.001;
    }
    else {
        die "Invalid PWM pin";
    }
}

method set-i2c-address(UByte:D $address) {
    self!write: EEPROM-BASE, EEPROM-I2C-ADDR, buf8.new($address);
    sleep(0.250);
    $!i2c-bus .= new(device => $i2c-device, address => $i2c-address);
    self.software-reset;
}

method get-i2c-address(--> UByte:D) {
    self!read8: EEPROM-BASE, EEPROM-I2C-ADDR;
}

method set-uart-baud(ULong:D $baud) {
    my buf8 $cmd .= new;
    $cmd.write-uint32: $baud;
    self!write: SERCOM0-BASE, SERCOM-BAUD, $cmd;
}

method !read32(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> ULong:D) {
    my $buf = self!read: $reg-base, $reg, 4, :$delay;
    $buf.read-uint32(0, BigEndian);
}

method !read16(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> UShort:D) {
    my $buf = self!read: $reg-base, $reg, 2, :$delay;
    $buf.read-uint16(0, BigEndian);
}

method !read8(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> UByte:D) {
    my $buf = self!read: $reg-base, $reg, 1, :$delay;
    $buf.read-uint8(0, BigEndian);
}

subset I2CReadLength of UInt where 32 >= * >= 1;
method !read(UByte:D $reg-base, UByte:D $reg, I2CReadLength:D $length, Rat:D() :$delay = 0.001 --> buf8:D) {
    self!write: $reg-base, $reg;
    with $.data-ready {
        until .value { #`[nop] }
    }
    else {
        sleep(delay);
    }

    buf8.new(gather take $!i2c-bus.read-byte for ^$length)
}

method !write(UByte:D $reg-base, UByte:D $reg, buf8:D $buf = buf8.new) {
    my buf8 $write-buf .= new($reg-base, $reg);
    $write-buf.append: $buf;

    with $.data-ready {
        until .value { #`[nop] }
    }

    $!i2c-bus.write-byte($_) for @($write-buf);
}

################################################################################
#
# These next two seem like curious out-of-place additions to this code that I'd
# like to move somewhere else.
#
method get-moisture(--> UTwelveBit:D) {
    my $moisture = 4096;
    for ^4 {
        return $moisture if $ret ~~ UTwelveBit;

        $moisture = self!read16:
            TOUCH-BASE,
            TOUCH-CHANNEL-OFFSET,
            :delay(0.005),
            ;
        sleep(0.001);
    }

    die "Could not get a valid moisture reading.";
}

method get-temperature(--> UShortRat:D) {
    my $value = self!read32(STATUS-BASE, STTATUS-TEMP, :delay(0.005));
    ($value +& 0x3FFF_FFFF) / 65536;
}

=begin pod

=head1 NAME

RPi::Device::SeeSaw - communicate with an Adafruit SeeSaw

=head1 DESCRIPTION

Provides complete interface to work with the Adafruit SeeSaw microcontroller module.

=head2 Bitsets

Most of the methods in this module work either directly or indirectly with bitsets. A bitset is just an integer where every bit represents a high/low boolean value. For example, here is an 8-bit wide bitset written out in binary:

    my $value = 0b00110101;

In this bitset, C<$value>, the 0, 2, 4, and 5 bits are high (or on or true, if you prefer) and the 1, 3, 6, and 7 bits are low (or off or false). You can construct a bitset from the bit positions as well. The following code constructs a value identical to the one above:

    my $value2 = [+|] for 0, 2, 4, 5 -> $bit { 1 +< $bit }
    say "{$value == $value2}"; #> True

That code uses the binary left shift operator to move a set bit left and then uses the binary-or operator to combine the bits into a single integer value.

To deconstruct a bitset, you can use an operation like the following:

    for ^8 -> $bit {\
        say "$bit is HIGH" if $value +& (1 +< $bit);
    }

    # Output:
    # 0 is HIGH
    # 2 is HIGH
    # 4 is HIGH
    # 5 is HIGH

If this is confusing, I highly recommend Elizabeth Mattijsen's L<Bits> module, which will do this sort of work for you.

B<CAVEAT:> To make things extra confusing, internally we have to break these integers down into bytes. This turns the integer into a series of integers represented by a Perl 6 L<Blob> type. The bytes are ordered from most significant to least significant so they can be sent in the correct order for the microcontroller to receive them (called big-endian order because the biggest values come first). This means the byte 0 of the Blob is the most signficant byte. It also means that if you use the C<read-ubits> method on Blob, bit 0 is the most significant rather than least significant bit. Be aware that if you encounter the bits as a Blob, the bit and byte ordering in Blobs is opposite of what we use for the bitsets in the SeeSaw interface.

=head2 Bulk Operations

Some SeeSaw operations are typically performed in bulk, meaning we talk to all the pins of a port at the same time. The SeeSaw firmware works on SAMD chips, which can have 64 pins. These pins are attached to 32-bit port registers, which each bit in the register controls the high/low voltage state of each pin. The bulk operations work with a whole port at a time.

The official Adafruit libraries for Arduino and CircuitPython provide two methods for working with the separate ports when such migth be necessary. For example, the Ardiuno library provides methods named C<digitalReadBulk> and C<digitalReadBulkB> for reading the digital pin values.

This library does this slightly differently. The "B" operations Adafruit performs are actually working with all 64-bits every time (they just only return 32-bit values). Since Perl 6 handles 64-bit integers just fine, I've opted instead to simply provide a single interface to these bulk methods which work with just the "A" port if a 32-bit value is provided or both ports if a 64-bit value is provided. No special separate operations are required here.

=head2 Pin Numbering

The pin numbers silk screened on the SeeSaw board DO NOT directly correspond to the bits in this interface. You must use the correct constants to work with the pin you want. For example, on a Circkit hat, signal pin 4 is bit 40, which corresponds to pin PB40 on port B. Always use the constants appropriate for your SeeSaw module.

=head1 ROLES

This role also implements L<RPi::Device::SeeSaw::Interface>, which defines the low-level routines required for communicating with SeeSaw firmware.

=head1 REQUIRED METHODS

=head2 method adc-pins

    method adc-pins(--> Map)

This method must return a map of port pin numbers to channel numbers for the Analog-to-Digital pins used for C<analog-read> operations.

=head2 method pwm-pins

    method pwm-pins(--> Map)

This method must return a map of port pin numbers to channel numbers for the Pulse-Width-Modulation pins used for C<analog-write> operations.

=head1 METHODS

=head2 method software-reset

    method software-reset()

Sends the signal to the SeeSaw to tell it to reset.

It is recommended that this method be called immediately after construction to help make sure the SeeSaw module is in a sane state and ready to communicate.

=head2 method get-options

    method get-options(--> ULong:D)

Returns the options flags from the SeeSaw module.

=head2 method get-version

    method get-version(--> ULong:D)

Returns the version information of the SeeSaw module. This can be used to determine which SeeSaw board is in use.

=head2 method pin-mode

    multi method pin-mode(
        PinNumber:D $pin,
        PinMode:D() $mode,
    )

This is used to modify the pin mode of a single pin, C<$pin>. The pin mode, C<$mode>, must be one of C<Input>, C<Output>, C<InputPullup> or C<InputPulldown>.

This method is a short hand for:

    $ss.pin-mode-bulk(1 +< $pin, $mode);

=head2 method pin-mode-bulk

    multi method pin-mode-bulk(
        PinBitset:D $mask,
        PinMode:D() $mode,
    );

This is used to modify the pin mode state of multiple pins at a time. If C<$mask> is 0, this does nothing. Otherwise, C<$mask> is used to identify which pins to grant the given mode, C<$mode>.

=head2 method analog-write

    multi method analog-write(
        PinNumber:D $pin,
        UShort:D $value,
    );

This sets the duty cycle for a pulse-width modulation (PWM) controlled pin, C<$pin>, to the given C<$value>. Lower values will mean a duty cycle with greater low voltage times while higher values will mean a duty cycle with greater high voltage times.

B<NOTE:> If you are used to Arduino's C<analogWrite()>, you should be aware that this value is an unsigned short integer with range 0 to 65535, note a byte as is the case in Arduino. So full on is 65535, NOT 255.

=head2 method digital-write

    multi method digital-write(
        PinNumber:D $pin,
        Bool:D() $value,
    )

When C<$value> is C<True>, changes the voltage of pin C<$pin> to high. Otherwise, changes the voltage of pin C<$pin> to low.

=head2 method digital-write-bulk

    multi method digital-write-bulk(
        PinBitset:D $mask,
        Bool:D() $value,
    )

Sets the voltage value for multiple digital pins at a time. All the pins selected by the on bits in C<$mask> will be changed. They will be set to a high voltage value if C<$value> is True or a low value otherwise.

=head2 method digital-read

    multi method set-digital-pin(
        PinNumber:D $pin,
        --> Bool:D
    )

Returns the digital state of pin C<$pin>. A return of C<True> indicates a high voltage state and C<False> indicates a low voltage state.

=head2 method digital-read-bulk

    multi method digital-read-bulk(--> PinBitset:D)

Retrieves the state of all pins at once.

For example, the following bitset will check the pins 2, 3, 4, 8, and 40:

    my $pins = $ss.get-digital-pins;

    my $pin2  = so $pins +& (1 +<  2);
    my $pin3  = so $pins +& (1 +<  3);
    my $pin4  = so $pins +& (1 +<  4);
    my $pin8  = so $pins +& (1 +<  8);
    my $pin24 = so $pins +& (1 +< 40);

=head2 method set-gpio-interrupts

    multi method set-gpio-interrupts(RPi::Device::SeeSaw:D:
        PinBitset:D $mask,
        Bool:D() $enabled,
    )

Enables change detection using interrupts. When enabled, the IRQ pin can be used to notify your application of changes in state to the given pins. Generally, this means the IRQ pin of the device will be pulled low and the falling edge of that pin should then be used to trigger an interrupt in your application so the change can be dealt with in real-time.

=head2 method analog-read

    multi method analog-read(
        PinNumber:D $channel,
        --> UShort:D
    )

Retrieves the ADC value from the given ADC channel, C<$channel>.

=head2 method touch-read

    multi method touch-read(
        PinNumber:D $channel,
        --> UShort:D
    )

Retrieves the analog value of a touch pad for the given touch channel, C<$channel>.

=head2 method set-pwm-frequency

    method set-pwm-frequency(
        PinNumber:D $pwm,
        UShort:D $frequency,
    )

Sets the PWM frequency for the given pin C<$pin> to the given value, C<$frquency>. Take some care when setting the frequency as some pins share a timer, so changing the frequency of one pin may change others.

=head2 method enable-sercom-data-ready-interrupt

    multi method enable-sercom-data-ready-interrupt(
        UByte:D $sercom = 0,
    );

For the given sercom channel, C<$sercom>, enable the data ready interrupt for serial communication on the given channel.

=head2 method disable-sercom-data-ready-interrupt

    multi method disable-sercom-data-ready-interrupt(
        Ubyte:D $sercom = 0,
    );

For the given sercom channel, C<$sercom>, disable the data ready interrupt for serial communication on the given channel.

=head2 method read-sercom-data

    multi method read-sercom-data(
        UByte:D $sercom = 0,
        --> UByte:D
    );

Read a single character from the sercom if data is available.

=head2 method eeprom-write

    multi method eeprom-write(UByte:D $addr, UByte:D $value)
    multi method eeprom-write(UByte:D $addr, blob8:D $buf)

Write a single byte value, C<$value>, or multiple bytes, C<$buf> to the EEPROM memory of the SeeSaw device starting at address, C<$addr>.

=head2 method eeprom-read

    method eeprom-read(UByte:D $addr --> UByte:D)

Read a single byte from the EEPROM of the SeeSaw device at memory location C<$addr>.

=head2 method set-i2c-address

    method set-i2c-address(RPi::Device::SeeSaw:D:
        UByte:D $address,
    )

Changes the I2C address used by the SeeSaw module. The default value is C<0x49>, but you can change it to something else. This value is written to EEPROM, so the change will be permanent until changed again (i.e., it will remain even if the SeeSaw is powered off).

This method also performs a software reset and resets the internal state of the object so it can talk to the SeeSaw at it's new I2C bus address.

=head2 method get-i2c-address

    method get-i2c-address(RPi::Device::SeeSaw:D: --> UByte:D)

I'm not certain what the point of this call would be since you have to know the I2C address of the SeeSaw module in order to query the I2C address.

=head2 method set-uart-baud

    method set-uart-baud(RPi::Device::SeeSaw:D:
        ULong:D $baud
    )

This sets the baud rate of the UART on the SeeSaw used for serial communication.

=head2 method set-keypad-event

    method set-keypad-event(
        UByte:D $key,
        KeypadEdge:D $edge,
        Bool:D $enable,
    );

Enable or disable event detection for a given key and detection edge.

=head2 method enable-keypad-interrupt

    method enable-keypad-interrupt()

Enables the interrupt firing on keypad events.

=head2 method disable-keypad-interrupt

    method disable-keypad-interrupt()

Disables the interrupt firing on keypad events.

=head2 method get-keypad-count

    method get-keypad-count(--> UByte:D)

Returns the number of events currently in the keypad event FIFO.

=head2 method read-keypad

    method read-keypad(UByte:D $count --> Seq:D)

Read keypad events from the event buffer. It will read C<$count> events and return them as a L<Seq> of L<RPi::Device::SeeSaw::Keypad::KeyEventRaw> objects. This have two accessors, one that returns the keypad edge that triggered the event and the key code on which that event was triggered.

=head2 method get-temperature

    method get-temperature(--> UShortRat:D)

Read the temperature of the SeeSaw module in degrees Celsius.

=head2 method get-encoder-position

    method get-encoder-position(--> LongInt:D)

Read the current position of the encoder.

=head2 method get-encoder-delta

    method get-encoder-delta(--> LongInt:D)

Read the change in encoder position since it was last read.

=head2 method set-encoder-position

    method set-encoder-position(LongInt:D $pos)

Set the current position of the encoder to C<$pos>.

=head2 method enable-encoder-interrupt

    method enable-encoder-interrupt()

Enables interrupt firing on encoder changes.

=head2 method disable-encoder-interrupt

    method disable-encoder-interrupt()

Disables interrupt firing on encoder changes.

=head1 PEDIGREE

This library has been built by porting the Adafruit libraries for the SeeSaw written in C and Python. However, I have endeavored to provide an idiomatically Perl 6 version of the library.

=item L<https://github.com/adafruit/Adafruit_Seesaw>

=item L<https://github.com/adafruit/Adafruit_CircuitPython_seesaw>

=end pod
