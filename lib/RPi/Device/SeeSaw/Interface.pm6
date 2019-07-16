use v6;

unit role RPi::Device::SeeSaw::Interface;

our constant SEESAW-DEFAULT-ADDRESS = 0x49;

has &.flow;

subset I2CReadLength of UInt where 32 >= * >= 1 is export(:short-names);

# Module Base Addresses
enum (
    Status-Base    => 0x00,
    GPIO-Base      => 0x01,
    SerCom0-Base   => 0x02,

    Timer-Base     => 0x08,
    ADC-Base       => 0x09,
    DAC-Base       => 0x0A,
    Interrupt-Base => 0x0B,
    DAP-Base       => 0x0C,
    EEPROM-Base    => 0x0D,
    NeoPixel-Base  => 0x0E,
    Touch-Base     => 0x0F,
    Keypad-Base    => 0x10,
    Encoder-Base   => 0x11,
) is export(:short-names);

# GPIO module function address registers
enum (
    GPIO-DirSet-Bulk => 0x02,
    GPIO-DirClr-Bulk => 0x03,
    GPIO-Bulk        => 0x04,
    GPIO-Bulk-Set    => 0x05,
    GPIO-Bulk-Clr    => 0x06,
    GPIO-Bulk-Toggle => 0x07,
    GPIO-IntEnSet    => 0x08,
    GPIO-IntEnClr    => 0x09,
    GPIO-IntFlag     => 0x0A,
    GPIO-PullEnSet   => 0x0B,
    GPIO-PullEnClr   => 0x0C,
) is export(:short-names);

# Status module funcction address registers
enum (
    Status-Hw-ID   => 0x01,
    Status-Version => 0x02,
    Status-Options => 0x03,
    Status-Temp    => 0x04,
    Status-SwRst   => 0x7F,
) is export(:short-names);

# Timer module function address registers
enum (
    Timer-Status => 0x00,
    Timer-PWM    => 0x01,
    Timer-Freq   => 0x02,
) is export(:short-names);

# ADC module function address registers
enum (
    ADC-Status         => 0x00,
    ADC-IntEn          => 0x02,
    ADC-IntEnClr       => 0x03,
    ADC-WinMode        => 0x04,
    ADC-WinThresh      => 0x05,
    ADC-Channel-Offset => 0x07,
) is export(:short-names);

# SerCom module function address registers
enum (
    SerCom-Status   => 0x00,
    SerCom-IntEn    => 0x02,
    SerCom-IntEnClr => 0x03,
    SerCom-Baud     => 0x04,
    SerCom-Data     => 0x05,
) is export(:short-names);

# NeoPixel module function address registers
enum (
    NeoPixel-Status     => 0x00,
    NeoPixel-Pin        => 0x01,
    NeoPixel-Speed      => 0x02,
    NeoPixel-Buf-Length => 0x03,
    NeoPixel-Buf        => 0x04,
    NeoPixel-Show       => 0x05,
) is export(:short-names);

# Touch module function address registers
enum (
    Touch-Channel-Offset => 0x10,
) is export(:short-names);

# Keypad module function address registers
enum (
    Keypad-Status   => 0x00,
    Keypad-Event    => 0x01,
    Keypad-IntEnSet => 0x02,
    Keypad-IntEnClr => 0x03,
    Keypad-Count    => 0x04,
    Keypad-FIFO     => 0x10,
) is export(:short-names);

# Keypad module edge definitions
enum KeypadEdge <
    Keypad-Edge-High
    Keypad-Edge-Low
    Keypad-Edge-Falling
    Keypad-Edge-Rising
> is export(:short-names);

# Encoder module function address registers
enum (
    Encoder-Status   => 0x00,
    Encoder-IntEnSet => 0x02,
    Encoder-IntEnClr => 0x03,
    Encoder-Position => 0x04,
    Encoder-Delta    => 0x05,
) is export(:short-names);

method read-uint64(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> ULongLong:D) {
    my $buf = self.read: $reg-base, $reg, 8, :$delay;
    $buf.read-uint64(0, BigEndian);
}

method read-uint32(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> ULong:D) {
    my $buf = self.read: $reg-base, $reg, 4, :$delay;
    $buf.read-uint32(0, BigEndian);
}

method read-uint16(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> UShort:D) {
    my $buf = self.read: $reg-base, $reg, 2, :$delay;
    $buf.read-uint16(0, BigEndian);
}

method read-uint8(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> UByte:D) {
    my $buf = self.read: $reg-base, $reg, 1, :$delay;
    $buf.read-uint8(0, BigEndian);
}

method read-int64(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> LongLong:D) {
    my $buf = self.read: $reg-base, $reg, 8, :$delay;
    $buf.read-int64(0, BigEndian);
}

method read-int32(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> Long:D) {
    my $buf = self.read: $reg-base, $reg, 4, :$delay;
    $buf.read-int32(0, BigEndian);
}

method read-int16(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> Short:D) {
    my $buf = self.read: $reg-base, $reg, 2, :$delay;
    $buf.read-int16(0, BigEndian);
}

method read-int8(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> Byte:D) {
    my $buf = self.read: $reg-base, $reg, 1, :$delay;
    $buf.read-int8(0, BigEndian);
}

method read(UByte:D $reg-base, UByte:D $reg, I2CReadLength:D $length, Rat:D() :$delay = 0.001 --> blob8:D) {
    do-write($reg-base, $reg);

    sleep $delay;
    with &.flow {
        until flow() { #`[nop] }
    }

    do-read($reg-base, $reg, $length, $delay);
}

method do-read(I2CReadLength:D $length, Rat:D() $delay --> blob8:D) {
    ...
}

method write-uint64(UByte:D $reg-base, UByte:D $reg, ULongLong:D $value) {
    my buf8 $buf .= new;
    $buf.write-uint64($value);
    self.write($reg-base, $reg, $buf);
}

method write-uint32(UByte:D $reg-base, UByte:D $reg, ULong:D $value) {
    my buf8 $buf .= new;
    $buf.write-uint32($value);
    self.write($reg-base, $reg, $buf);
}

method write-uint16(UByte:D $reg-base, UByte:D $reg, UShort:D $value) {
    my buf8 $buf .= new;
    $buf.write-uint16($value);
    self.write($reg-base, $reg, $buf);
}

method write-uint8(UByte:D $reg-base, UByte:D $reg, UByte:D $value) {
    my buf8 $buf .= new;
    $buf.write-uint8($value);
    self.write($reg-base, $reg, $buf);
}

method write-int64(UByte:D $reg-base, UByte:D $reg, LongLong:D $value) {
    my buf8 $buf .= new;
    $buf.write-int64($value);
    self.write($reg-base, $reg, $buf);
}

method write-int32(UByte:D $reg-base, UByte:D $reg, Long:D $value) {
    my buf8 $buf .= new;
    $buf.write-int32($value);
    self.write($reg-base, $reg, $buf);
}

method write-int16(UByte:D $reg-base, UByte:D $reg, Short:D $value) {
    my buf8 $buf .= new;
    $buf.write-int16($value);
    self.write($reg-base, $reg, $buf);
}

method write-int8(UByte:D $reg-base, UByte:D $reg, Byte:D $value) {
    my buf8 $buf .= new;
    $buf.write-int8($value);
    self.write($reg-base, $reg, $buf);
}

method write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf = blob8.new) {
    with &.flow {
        until flow() { #`[nop] }
    }

    self.do-write($reg-base, $reg, $buf);
}

method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf = blob8.new) {
    ...
}

=begin pod

=head1 NAME

RPi::Device::SeeSaw::Interface - lays out the structure of the low-level interface to SeeSaw

=head1 SYNOPSIS

    use v6;

    use RPi::Device::SeeSaw::Interface :short-names;

    unit class RPi::Device::SeeSaw::Interface::Foo does RPi::Device::SeeSaw::Interface;

    method do-read(IC2ReadLength:D $len --> blob8:D) {
        # read from the interface
    }

    method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf) {
        # write to the interface
    }

=head1 DESCRIPTION

This role defines the interface for talking to a SeeSaw module. This module also defines the constants used for communicating with the hardware module.

=head1 CONSTANTS

The following constants are the module base addresses:

    Status-Base
    GPIO-Base
    SerCom0-Base

    Timer-Base
    ADC-Base
    DAC-Base
    Interrupt-Base
    DAP-Base
    EEPROM-Base
    NeoPixel-Base
    Touch-Base
    Keypad-Base
    Encoder-Base

These constants address the GPIO registers:

    GPIO-DirSet-Bulk
    GPIO-DirClr-Bulk
    GPIO-Bulk
    GPIO-Bulk-Set
    GPIO-Bulk-Clr
    GPIO-Bulk-Toggle
    GPIO-IntEnSet
    GPIO-IntEnClr
    GPIO-IntFlag
    GPIO-PullEnSet
    GPIO-PullEnClr

These constants address the Status registers:

    Status-Hw-ID
    Status-Version
    Status-Options
    Status-Temp
    Status-SwRst

These constants address the Timer registers:

    Timer-Status
    Timer-PWM
    Timer-Freq

These constants address the ADC registers:

    ADC-Status
    ADC-IntEn
    ADC-IntEnClr
    ADC-WinMode
    ADC-WinThresh
    ADC-Channel-Offset

These constants address teh SerCom registers:

    SerCom-Status
    SerCom-IntEn
    SerCom-IntEnClr
    SerCom-Baud
    SerCom-Data

These constants address teh NeoPixel registers:

    NeoPixel-Status
    NeoPixel-Pin
    NeoPixel-Speed
    NeoPixel-Buf-Length
    NeoPixel-Buf
    NeoPixel-Show

These constants address the touch registers:

    Touch-Channel-Offset

These constants address the Keypad registers:

    Keypad-Status
    Keypad-Event
    Keypad-IntEnSet
    Keypad-IntEnClr
    Keypad-Count
    Keypad-FIFO

These are the keypad module edge definitions:

    Keypad-Edge-High
    Keypad-Edge-Low
    Keypad-Edge-Falling
    Keypad-Edge-Rising

These constants address the encoder registers:

    Encoder-Status
    Encoder-IntEnSet
    Encoder-IntEnClr
    Encoder-Position
    Encoder-Delta

=head1 REQUIRED METHODS

Implementations must implemented the following methods.

=head2 method do-read

    method do-read(I2CReadLength:D $length --> blob8:D)

This reads C<$length> bytes of data from the hardware module and returns those bytes in an 8-bit C<Blob>.

=head2 method do-write

    method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf)

This should write the register bytes C<$reg-base> and C<$reg> followed by the 0 or more bytes found in the 8-bit C<Blob>, C<$buf>.

=head1 METHODS

=head2 method new

    method new(
        :&flow = { True },
        --> RPi::Device::SeeSaw::Interface:D
    )

This creates an object that is able to interface with the SeeSaw board. The SeeSaw protocol is a layer on top of I2C. The C<$i2c-device> and C<$i2c-address> parameters connect to the SeeSaw on the named device file and I2C address. These should have reasonable defaults that work for most applications.

The C<&flow> function controls the flow of data. The routine is used to control when access to the I2C bus is enabled. Whenever data is to be read from or written to the I2C device, this function will be called prior to performing the action. If the function returns a C<False> value, the operation will block. The function will continue to be called until the function returns a C<True> value.

=head2 method read-uint8
=head2 method read-uint16
=head2 method read-uint32
=head2 method read-uint64
=head2 method read-int8
=head2 method read-int16
=head2 method read-int32
=head2 method read-int64

    method read-uint8(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> UByte:D)
    method read-uint16(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> UShort:D)
    method read-uint32(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> ULong:D)
    method read-uint64(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> ULongLong:D)
    method read-int8(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> Byte:D)
    method read-int16(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> Short:D)
    method read-int32(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> Long:D)
    method read-int64(UByte:D $reg-base, UByte:D $reg, Rat:D() :$delay = 0.001 --> LongLong:D)

Given a register base module, C<$reg-base>, and a register address, C<$reg>, this will read data from that module register. The number of bits read is determined by the number of bits in the function name. The value returned will be an integer with no more than the specified number of bits.

The C<$delay> injects a slight pause after the read and before returning. I don't know why. I should figure that out.

=head2 method read

    method read(UByte:D $reg-base, UByte:D $reg, UInt:D $length, Rat:D() :$delay = 0.001 --> blob8:D)

Given a register base module, C<$reg-base>, and a register address, C<$reg>, this will read C<$length> bytes of data from that module register. The data is returned as a L<Blob> containing the number of bytes read.

The C<$delay> injects a slight pause after the read and before returning.

=head2 method write-uint8
=head2 method write-uint16
=head2 method write-uint32
=head2 method write-uint64
=head2 method write-int8
=head2 method write-int16
=head2 method write-int32
=head2 method write-int64

    method write-uint64(UByte:D $reg-base, UByte:D $reg, ULongLong:D $value)
    method write-uint32(UByte:D $reg-base, UByte:D $reg, ULong:D $value)
    method write-uint16(UByte:D $reg-base, UByte:D $reg, UShort:D $value)
    method write-uint8(UByte:D $reg-base, UByte:D $reg, UByte:D $value)
    method write-int64(UByte:D $reg-base, UByte:D $reg, ULongLong:D $value)
    method write-int32(UByte:D $reg-base, UByte:D $reg, ULong:D $value)
    method write-int16(UByte:D $reg-base, UByte:D $reg, UShort:D $value)
    method write-int8(UByte:D $reg-base, UByte:D $reg, UByte:D $value)

Given a register base module, C<$reg-base>, and a register address, C<$reg>, and a C<$value> to set, this will write the value to the register. The number in the function name is the number of bits to write.

=head2 method write

    method write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf = blob8.new)

Given a register base module, C<$reg-base>, and a register address, C<$reg>, it will write data to the register. The register address may optionally be followed by additional bytes to write to the register.

=end pod
