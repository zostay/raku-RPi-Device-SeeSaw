use v6;

use RPi::Device::SeeSaw::Interface :ALL;
use RPi::Device::SeeSaw::Types :ALL;

unit role RPi::Device::SeeSaw::Interface::Delegate does RPi::Device::SeeSaw::Interface;

has RPi::Device::SeeSaw::Interface $.delegate is required;

method do-read(I2CReadLength:D $length --> blob8:D) {
    $.delegate.do-read($length);
}

method do-write(UByte:D $reg-base, UByte:D $reg, blob8:D $buf) {
    $.delegate.do-write($reg-base, $reg, $buf);
}

=begin pod

=head1 NAME

RPi::Device::SeeSaw::Interface::Delegate - delegate low-level communication to another class

=head1 SYNOPSIS

    use v6;

    use RPi::Device::SeeSaw::Interface :ALL;
    use RPi::Device::SeeSaw::Interface::I2C;
    use RPi::Device::SeeSaw::Interface::Delegate;

    class MyFoo does RPi::Device::SeeSaw::Interface::Delegate { }

    my MyFoo $foo .= new(
        delegate => RPi::Device::SeeSaw::Interface::I2C.new,
    );

    $foo.write-uint32(Status-Base, Status-SwRst, 0xFF);

=head1 DESCRIPTION

This is intended to provide a delegate interface to allow a class to both implement the SeeSaw I2C interface, but to send calls to that interface to a delegate. This allows the I2C interface to be implemented in different ways in the future and also makes testing easier.

=head1 METHODS

See L<RPi::Device::SeeSaw::Interface> for most of the methods implemented. We only describe the parts specific to this implementation here.

=head2 method new

    method new(
        RPi::Device::SeeSaw::Interface :$delegate!,
        :&flow = { True },
    )

Constructs a new object with the given control flow guard, C<&flow>. The object will delegate all calls to C<$delegate>.

=head2 method delegate

    method delegate(--> RPi::Device::SeeSaw::Interface)

This is the interface to which all calls to this interface will be delegated.

=end pod
