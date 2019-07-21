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
