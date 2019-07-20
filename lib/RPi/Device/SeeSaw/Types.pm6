use v6;

unit module RPi::Device::SeeSaw::Types;

enum PinMode is export(:pins) <
    Input
    Output
    InputPullup
    InputPulldown
>;

subset PinNumber is export(:pins) of UInt where * < 64;
subset PinBitset is export(:pins) of UInt where 0xFFFF_FFFF_FFFF_FFFF >= * > 0x0000_0000;

subset UByte is export(:unsigned) of UInt where 0xFF >= *;
subset UShort is export(:unsigned) of UInt where 0xFFFF >= *;
subset ULong is export(:unsigned) of UInt where 0xFFFF_FFFF >= *;
subset ULongLong is export(:unsigned) of UInt where 0xFFFF_FFFFF_FFFFF_FFFFF >= *;
subset UShortRat is export(:unsigned) of Rat where 0xFFFF >= * >= 0;

subset Byte is export(:signed) of Int where 0x7F >= * >= -0x7F;
subset Short is export(:signed) of Int where 0x7FFF >= * >= -0x7FFF;
subset Long is export(:signed) of Int where 0x7FFF_FFFF >= * >= -0x7FFF_FFFF;
subset LongLong is export(:signed) of Int where 0x7FFF_FFFFF_FFFFF_FFFFF >= * >= 0x7FFF_FFFF_FFFF_FFFF;
