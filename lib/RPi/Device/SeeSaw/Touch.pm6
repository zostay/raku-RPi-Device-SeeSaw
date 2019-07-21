use v6;

unit role RPi::Device::SeeSaw::Touch;

method touch-pins(--> Hash[Int, Int]) { ... }

method touch-read(PinNumber:D $pin --> UShort:D) {
    die "Invalid touch pin"
        without $.touch-pins.{ $pin };

    self.read-uint16:
        Touch-Base,
        Touch-Channel-Offset + $.touch-pins.{ $pin },
        ;
}

=begin pod

=head2 method touch-read

    multi method touch-read(
        PinNumber:D $channel,
        --> UShort:D
    )

Retrieves the analog value of a touch pad for the given touch channel, C<$channel>.

=end pod
