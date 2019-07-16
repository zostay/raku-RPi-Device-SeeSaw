use v6;

unit module RPi::Device::SeeSaw::Types;

enum PinMode <
    Input
    Output
    InputPullup
    InputPulldown
> is export(:short-names);

subset PinNumber of UInt where * < 64 is export(:short-names);
subset PinBitset of UInt where 0xFFFF_FFFF_FFFF_FFFF >= * > 0x0000_0000 is export(:short-names);
subset PinBank of Str where * eq 'A' | 'B' is export(:short-names);
subset UByte of UInt where 0xFF >= * is export(:short-names);
subset UShort of UInt where 0xFFFF >= * is export(:short-names);
subset ULong of UInt where 0xFFFF_FFFF >= * is export(:short-names);
subset ULongLong of UInt where 0xFFFF_FFFFF_FFFFF_FFFFF >= * is export(:short-names);
subset UTwelveBit of UInt where 0x1000 > * is export(:short-names);
subset UShortRat of Rat where 0xFFFF >= * >= 0;
