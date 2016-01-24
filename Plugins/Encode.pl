addPlug("Encode", {
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Encode',
  'dependencies' => ['Core_Utilities'],
  'utilities' => {
    ### Encoding
    ## Stupid shit
    'enreverse' => sub { return join "", reverse split //, $_[0]; },
    'enlower' => sub { return lc $_[0]; },
    'enupper' => sub { return uc $_[0]; },
    'ennowhite' => sub { my $string = $_[0]; $string =~ s/\s//g; return $string; },
    ## Hard core shit
    # Binary
    'enbinary' => sub { return unpack("B*",$_[0]); },
    'debinary' => sub { return unpack("A*", pack("B*", $_[0])); },
    # Hex
    'endecimal' => sub { return join " ", unpack("C" x length($_[0]),$_[0]); }, 
    'dedecimal' => sub {
      my @dec = split /\s+/, $_[0];
      for ($i=0;$i<=$#dec;$i++) {
        $dec[$i]=unpack("A*", pack("N", $dec[$i]));
        $dec[$i]=~s/^0+(?=\d{8})//;
      }
      return join "", @dec;
    },
    'enhexadecimal' => sub { return join " ", unpack("H2" x length($_[0]), pack("A*",$_[0])); }, 
    ## Oh god what am I doing
    'enrot' => sub {
      if($_[0] =~ /^(\d+)\s+(.+)$/) {
        my ($shift,$text) = ($1,$2);
        if($shift == 13) {
          $text =~ tr[A-Za-z][N-ZA-Mn-za-m];
        }
        return $text;
      }
      return ">>Usage: >>Encode rot >>NUMBER \x04super secret code here";
    },
  },
  'commands' => {
    '^Encode (\w+) (.+)$' => {
      'description' => "Encodes stuff from ascii.",
      'code' => sub {
        my ($encoding, $text) = (lc $1,$2);
        if($utility{'Encode_en'.$encoding}) { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},&{$utility{'Encode_en'.$encoding}}($text)); }
        else { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"No encoding with name >>$encoding."); }
      }
    },
    '^Decode (\w+) (.+)$' => {
      'description' => "Decodes stuff to ascii.",
      'code' => sub {
        my ($encoding, $text) = (lc $1,$2);
        if($utility{'Encode_de'.$encoding}) { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},&{$utility{'Encode_de'.$encoding}}($text)); }
        else { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"No decoding with name >>$encoding."); }
      }
    },
    '^Decode$' => {
      'description' => "Shows things you can decode from.",
      'code' => sub {
        my @encoding = ();
        foreach(keys %utility) { if(/^Encode_de(.+)$/) { push(@encoding,"[\x04$1\x04]"); } }
        &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"You can decode from: ".(join " ", @encoding));
      }
    },
    '^Encode$' => {
      'description' => "Shows things you can encode into.",
      'code' => sub {
        my @encoding = ();
        foreach(keys %utility) { if(/^Encode_en(.+)$/) { push(@encoding,"[\x04$1\x04]"); } }
        &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"You can encode to: ".(join " ", @encoding));
      }
    },
  }
});