
use v6.0.0;

# http://perldoc.perl.org/overload.html
my $fallback;
my %ops = (
    # export both <+> and <P5+>, so that overloading works from v5 and v6 land?
    '0+'   => '&prefix:<P5+>', # like .Numeric
    '""'   => '&prefix:<P5.>', # like .Str
    'bool' => '&prefix:<P5?>', # like .Bool
    '+'    => '&infix:<P5+>',
    '<=>'  => '&infix:<P5<=>>',
);

sub EXPORT(*@ops) {
    my %o;
    for @ops -> $k, $v {
        if $k eq 'fallback' {
            $fallback := $v;
            next
        }
        my $sub        := $v ~~ Str ?? ::($v) !! $v; # Make an indirect sub call if key is a string.
        %o{ %ops{$k} } := $sub if %ops{$k};
        %o{ $k }       := 1;
    }
    
    if !nqp::defined($fallback) || $fallback {
        for %o.kv -> $k, $v {
            given $k {
                when '&infix:<P5+>' {
                    #~ %o{'&infix:<P5->'} := -> $a, $b { $v($b, $a, 1) } unless %o{'&infix:<P5->'}
                }
                
                when '&infix:<P5<=>>' {
                    %o{'&infix:<P5==>'} := { $^a, $^b; $v($a, $b) == 0 } unless %o{'&infix:<P5==>'};
                    %o{'&infix:<P5>=>'} := { $^a, $^b; $v($a, $b) >= 0 } unless %o{'&infix:<P5>=>'};
                    %o{'&infix:<P5<=>'} := { $^a, $^b; $v($a, $b) <= 0 } unless %o{'&infix:<P5<=>'};
                    %o{'&infix:<P5>>'}  := { $^a, $^b; $v($a, $b) >  0 } unless %o{'&infix:<P5>>'};
                    %o{'&infix:<P5<>'}  := { $^a, $^b; $v($a, $b) <  0 } unless %o{'&infix:<P5<>'};
                    %o{'&infix:<P5!=>'} := { $^a, $^b; $v($a, $b) != 0 } unless %o{'&infix:<P5!=>'};
                }
            }
        }
    }
    
    #~ If a method for an operation is not found then Perl tries to autogenerate a substitute implementation
    #~ from the operations that have been defined.
    #~ Note: the behaviour described in this section can be disabled by setting fallback to FALSE (see fallback).
    #~ In the following tables, numbers indicate priority. For example, the table below states that, if no
    #~ implementation for '!' has been defined then Perl will implement it using 'bool' (that is, by inverting
    #~ the value returned by the method for 'bool' ); if boolean conversion is also unimplemented then Perl will
    #~ use '0+' or, failing that, '""' .

    #~ operator | can be autogenerated from
    #~          |
    #~          | 0+    ""  bool    .   x
    #~ =========|==========================
    #~ 0+       |       1   2
    #~ ""       | 1         2
    #~ bool     | 1     2
    #~ int      | 1     2   3
    #~ !        | 2     3   1
    #~ qr       | 2     1   3
    #~ .        | 2     1   3
    #~ x        | 2     1   3
    #~ .=       | 3     2   4       1
    #~ x=       | 3     2   4           1
    #~ <>       | 2     1   3
    #~ -X       | 2     1   3
    #~ Note: The iterator ('<>' ) and file test ('-X' ) operators work as normal: if the operand is not a blessed
    #~ glob or IO reference then it is converted to a string (using the method for '""' , '0+' , or 'bool' ) to
    #~ be interpreted as a glob or filename.

    #~ operator | can be autogenerated from
    #~          |
    #~          | <     <=>   neg   -=    -
    #~ =========|==========================
    #~ neg      |                         1
    #~ -=       |                         1
    #~ --       |                   1     2
    #~ abs      | a1    a2    b1         b2 [*]
    #~ <        |       1
    #~ <=       |       1
    #~ >        |       1
    #~ >=       |       1
    #~ ==       |       1
    #~ !=       |       1
    #~ * one from [a1, a2] and one from [b1, b2]


    #~ Just as numeric comparisons can be autogenerated from the method for '<=>' , string comparisons can be
    #~ autogenerated from that for 'cmp' :
    #~ operators           | can be autogenerated from
    #~ ====================|===========================
    #~ lt gt le ge eq ne   | cmp


    #~ Similarly, autogeneration for keys '+=' and '++' is analogous to '-=' and '--' above:
    #~ operator | can be autogenerated from
    #~          |
    #~          | +=    +
    #~ =========|==========================
    #~ +=       |       1
    #~ ++       | 1     2


    #~ And other assignment variations are analogous to '+=' and '-=' (and similar to '.=' and 'x=' above):
    #~ operator           || *= /= %= **= <<= >>= &= ^= |=
    #~ -------------------||--------------------------------
    #~ autogenerated from || *  /  %  **  <<  >>  &  ^  |

    %o
}

module overload {
    
}
