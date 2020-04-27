use v6;

use RPi::Device::SeeSaw::Common;

unit class RPi::Device::Crickit does RPi::Device::SeeSaw::Common does RPi::Device::SeeSaw::Touch;

our constant DEFAULT-ADDRESS = 0x49;

enum Signal-IO is export(:pins, :signals) (
    Signal1 => 2,
    Signal2 => 3,
    Signal3 => 40,
    Signal4 => 41,
    Signal5 => 11,
    Signal6 => 10,
    Signal7 => 9,
    Signal8 => 8,
);

enum Servo-Output is export(:pins, :servos) (
    Servo4 => 14,
    Servo3 => 15,
    Servo2 => 16,
    Servo1 => 17,
);

enum Motor-Output is export(:pins, :motors) (
    Motor-A1 => 22,
    Motor-A2 => 23,
    Motor-B1 => 19,
    Motor-B2 => 18,
);

enum Drive-Output is export(:pins, :drives) (
    Drive1 => 13,
    Drive2 => 12,
    Drive3 => 43,
    Drive4 => 42,
);

enum Touch-Input is export(:pins, :touch) (
    Touch1 => 0,
    Touch2 => 1,
    Touch3 => 2,
    Touch4 => 3,
);

my constant Int %ADC-PINS{Int} =
    Signal1, 0,
    Signal2, 1,
    Signal3, 2,
    Signal4, 3,
    Signal5, 4,
    Signal6, 5,
    Signal7, 6,
    Signal8, 7,
    ;

method adc-pins(--> Hash[Int, Int]) { %ADC-PINS }

my constant Int %PWM-PINS{Int} =
    Servo4, 0,
    Servo3, 1,
    Servo2, 2,
    Servo1, 3,
    Motor-B1, 4,
    Motor-B2, 5,
    Motor-A1, 6,
    Motor-A2, 7,
    Drive4, 8,
    Drive3, 9,
    Drive2, 10,
    Drive1, 11,
    ;

method pwm-pins(--> Hash[Int, Int]) { %PWM-PINS }

=begin pod

=head1 NAME

RPi::Device::Crickit - communicate with an Adafruit Crickit

=head1 DESCRIPTION

Provides complete interface to work with the Adafruit Crickit Hat for Raspberry Pi.

This module is a specialized version of L<RPi::Device::SeeSaw>, so you can find much of the documentation there. It won't be duplicated here. However, here will be documented the constants and features specific to Crickit.

=head1 EXPORTED ENUMS

=head2 enum Signal-IO

This enumerates the signal pins for use with the Crickit Hat. The values are C<Signal1> through C<Signal8>.

These are exported with the C<:pins> and C<:signals> export tags.

=head2 enum Servo-Output

This enumerates the servo output pins for use with the Crickit Hat. The values are C<Servo1> through C<Servo4>.

These are exported with the C<:pins> and C<:servors> export tags.

=head2 enum Motor-Output

This enumerates the motor output pins for use with the Crickit Hat. The values are C<Motor-A1>, C<Motor-A2>, C<Motor-B1>, and C<Motor-B2>.

These are exported with the C<:pins> and C<:motors> export tags.

=head2 enum Drive-Output

This enumerates the solinode driver pins for use with the Crickit Hat. The values are C<Drive1> through C<Drive4>.

These are exported with the C<:pins> and C<:drives> export tags.

=head2 enum Touch-Input

This enumerates the capacitive touch pins for use with the Crickit Hat. The values are C<Touch1> through C<Touch4>.

These are exported with the C<:pins> and C<:touch> export tags.

=head1 METHODS

=head2 method adc-pins

    method adc-pins(--> Hash[Int, Int])

This method should rarely be needed in end-user code.

This lists the pins that are capable of analog reads via the ADC. This is a map from pin value found in the various exported enumerations to the value used by the SeeSaw firmware on the Crickit.

=head2 method pwm-pins

    method pwm-pins(--> Hash[Int, Int])

This method should rarely be needed in end-user code.

This lists the pins that are capable of PWM operation, i.e., analog writes. This is a map from pin value found in the various exported enumerations to the value used by the SeeSaw firmware on the Crickit.

=end pod
