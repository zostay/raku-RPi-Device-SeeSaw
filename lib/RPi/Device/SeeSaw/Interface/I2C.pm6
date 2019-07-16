use v6;

use RPi::Device::SeeSaw::Interface;
use RPi::Device::SMBus;

unit class RPi::Device::SeeSaw::Interface::I2C does RPi::Device::SeeSaw::Interface;

has Str $.i2c-device = '/dev/i2c-1';
has Int $.i2c-address = SEESAW-DEFAULT-ADDRESS;
has RPi::Device::SMBus $!i2c-bus;

# This method builds the I2C bus object lazily. It is not documented
# because this bit will surely change if I add support for I2C using
# RPi::Wiring.
method i2c-bus(--> RPi::Device::SMBus:D) {
    return $_ with $!i2c-bus;
    $!i2c-bus .= new(device => $i2c-device, address => $i2c-address);
}

method do-read(I2CReadLength:D $length --> blob8:D) {
    blob8.new(gather take $.i2c-bus.read-byte for ^$length)
}

method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf) {
    my buf8 $write-buf .= new($reg-base, $reg);
    $write-buf.append: $buf;

    $.i2c-bus.write-byte($_) for @($write-buf);
}

=begin pod

=head1 NAME

RPi::Device::SeeSaw::Interface::I2C - low-level communication over I2C

=head1 SYNOPSIS

    use v6;

    use RPi::Device::SeeSaw::Interface :short-names;
    use RPi::Device::SeeSaw::Interface::I2C;

    my $iface = RPi::Device::SeeSaw::Interface::I2C.new;

    $iface.write-uint8: Status-Base, Status-SwRst, 0xFF;
    my $pins = $iface.read-uint32: GPIO-Base, GPIO-Base;

    # check to see if pin 0 is high
    if $pins +& 0x01 {
        say "Pin 0 is High";
    }

=head1 DESCRIPTION

This class provides a number of low-level tools to make communicating with a SeeSaw module a little simpler.

=head1 METHODS

=head2 method new

    method new(
        Str :$i2c-device = '/dev/ic2-1',
        Int :$i2c-address = 0x49,
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
