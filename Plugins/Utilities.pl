addPlug('Util', {
  'creator' => 'Caaz',
  'version' => '2',
  'name' => 'Utilities',
  'description' => "Who needs Core_Utilities. This is gonna be the latest advancement in utility technology, featuring a safer way to cross plugin script.",
  code => {
    load => sub {
      %u = ();
      # Throw all utilities into %u!
      foreach $plugin (keys %{$lk{plugin}}) {
        %{$u{$plugin}} = %{$lk{plugin}{$plugin}{utilities}};
      }
    }
  },
  'utilities' => {
    'findS' => sub {
      # Input: HashRef, Key, Regex
      # Output: String
      return "Found: ".(join ", ", @{$utility{'Util_find'}(shift,shift,shift)});
    },
    'find' => sub {
      my ($hash,$key,$regex) = (shift,shift,shift);
      my @found = (); 
      foreach $k (keys %{ $hash }){
        push(@found,$k) if(($$hash{$k}{$key}) && ($$hash{$k}{$key} =~ /$regex/i)); 
      }
      @found = sort(@found); 
      return \@found;
    },
    'debugP' => sub {
      # Input: Reference, (Key)?, (Indent)?
      # Output: 1
      print join "\n", $utility{'Util_debug'}(shift,shift); print "\n";
      return 1;
    },
    'debug' => sub {
      # Input: Reference, (Key)?, (Indent)?
      # Output: Structure of reference in an array.
      my $ref = $_[0];
      my $indent = '';
      my $key = ($_[1])?"$_[1]: ":"0: ";
      my $indentNum = ($_[2])?$_[2]:0;
      for(my $i = 0; $i <= $indentNum; $i++) { $indent .= "  "; } $indent =~ s/^  //;
      if($ref =~ /^HASH/) {
        my @return = ($indent.$key."{");
        foreach(keys %{$ref}) { push(@return,$utility{'Util_debug'}(${$ref}{$_},$_,$indentNum+1)); }
        push(@return,$indent."}");
        return @return;
      }
      elsif($ref =~ /^ARRAY/) {
        my @return = ($indent.$key."[");
        my $i = 0;
        foreach(@{$ref}) { push(@return,$utility{'Util_debug'}($_,$i,$indentNum+1)); $i++; }
        push(@return,$indent."]");
        return @return;
      }
      elsif($ref =~ /^SCALAR/) { return $indent.$key.${$ref}; }
      elsif($ref =~ /^CODE/) { return $indent.$key."*CODE*"; }
      else { return $indent.$key.$ref; }
    },
    'use' => {
      # Input: Plugin, Utility, Arguments!
      # Output: A hash containing information about return values.
    }
  }
});