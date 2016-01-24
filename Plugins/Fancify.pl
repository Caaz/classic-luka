addPlug("Fancify", {
  'creator' => 'Caaz',
  'version' => '3.1',
  'name' => 'Fancify',
  'dependencies' => ['Core_Command'],
  'commands' => {
    '^GlobalFancy (\d{1,2},\s*\d{1,2})$' => {
      'description' => "Changes Fancify colors.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub {
        my @colors = split /\,\s*/, $1;
        for(@colors) { $_ = '0'.$_ if(($_<10) and ($_ !~ /^0/)); }
        @{$lk{data}{plugins}{'Fancify'}{colors}} = @colors;
        &{$lk{plugin}{"Fancify"}{utilities}{say}}($_[1]{irc},$_[2]{where},"Updated colors >>globally.");
      }
    },
    '^Fancy (\d{1,2},\s*\d{1,2})$' => {
      'description' => "Changes Fancify colors for a specific channel.",
      'tags' => ['utility'],
      'code' => sub {
        my @colors = split /\,\s*/, $1;
        for(@colors) { $_ = '0'.$_ if(($_<10) and ($_ !~ /^0/)); }
        @{$lk{data}{plugins}{'Fancify'}{$_[2]{where}}} = @colors;
        &{$lk{plugin}{"Fancify"}{utilities}{say}}($_[1]{irc},$_[2]{where},"Updated colors for $_[2]{where}!");
      }
    },
    '^Fancy$' => {
      'description' => "Changes Fancify colors for a specific channel.",
      'tags' => ['utility'],
      'code' => sub {
        delete $lk{data}{plugins}{'Fancify'}{$_[2]{where}};
        &{$lk{plugin}{"Fancify"}{utilities}{say}}($_[1]{irc},$_[2]{where},"Deleted colors for $_[2]{where}!");
      }
    }
  },
  'utilities' => {
    'main' => sub {
      my @colors ;
      if($_[1]) { @colors = @{$_[1]}; }
      elsif($lk{data}{plugins}{'Fancify'}{colors}) { @colors = @{$lk{data}{plugins}{'Fancify'}{colors}}; }
      else { @colors = (14,13); }
      my $color = 0;
      my $rainbow = 0;
      my $rbPos = 0;
      my $rbCode = sub { my $text = '' ; for(split //, $_[0]) { $_[1]++; if($_[1] >= @{$_[2]}) { $_[1] = 0; } $text .= "\cC$_[2][$_[1]]".$_; } return $text."\cC$colors[0]"; };
      my @rb = ('04','07','08','09','11','12','06','13');
      if(($colors[0] + $colors[1]) == 50) { @colors = (14,14); $rainbow = 1; } 
      my $string = "\cC$colors[0]".$_[0];
      my @string = split //, $string;
      for(@string) {
        if($rainbowing) { 
          $rbPos++; if($rbPos >= @rb) { $rbPos = 0; } $_ = "\cC$rb[$rbPos]".$_; 
        }
        if(/\x04/) { 
          $color++; if($color >= @colors) { $color = 0; } 
          if($rainbow) {
            if(!$rainbowing) { 
              $rainbowing = 1;
              $rbPos = -1;
              $_ = ''; 
            }
            else {
              $rainbowing = 0;
              $_ = "\cC$colors[0]"; 
            }
          }
          else {
            $_ = "\cC$colors[$color]"; 
          }
        } 
      }
      $string = join "", @string;
      if(!$rainbow) {
        $string =~ s/((?:\#|\@)+[\w\-\/.]+)/\cC$colors[1]$1\cC$colors[0]/g; # Hashtag/Channel coloring
        $string =~ s/([a-z]+:\/\/\S+\.[a-z]{2,6}\/?(?:[\/\w=?]+)?)/\cC$colors[1]$1\cC$colors[0]/gi; # URL coloring.
        $string =~ s/(?:\x05|>>)([\w]+)/\cC$colors[1]$1\cC$colors[0]/g; # >> or \x05 word coloring.
        $string =~ s/\cC\d{1,2}(?:,\d{1,2})?(\cC\d{1,2}(?:,\d{1,2})?)/$1/g; # Remove extra colorcodes.
      }
      else {
        $string =~ s/((?:\#|\@)+[\w\-\/.]+)/&{$rbCode}($1,\$rbPos,\@rb)/eg; # Hashtag/Channel coloring
        $string =~ s/([a-z]+:\/\/\S+\.[a-z]{2,6}\/?(?:[\/\w=?]+)?)/&{$rbCode}($1,\$rbPos,\@rb)/egi; # URL coloring.
        $string =~ s/(?:\x05|>>)([\w]+)/&{$rbCode}($1,\$rbPos,\@rb)/eg; # >> or \x05 word coloring.
        $string =~ s/\cC\d{1,2}(?:,\d{1,2})?(\cC\d{1,2}(?:,\d{1,2})?)/$1/g; # Remove extra colorcodes.
      }
      return $string;
    },
    'say' => sub {
      # Filehandle, Where, What.
      my @lines = split /\n/, $_[2];
      for(@lines) {
        if(/^\s*?$/) { next; }
        lkRaw($_[0],"PRIVMSG $_[1] :".&{$lk{plugin}{'Fancify'}{utilities}{main}}($_,($lk{data}{plugins}{'Fancify'}{$_[1]})?$lk{data}{plugins}{'Fancify'}{$_[1]}:($lk{data}{plugins}{'Fancify'}{colors})?$lk{data}{plugins}{'Fancify'}{colors}:0));
        select(undef, undef, undef, 0.25) if(@lines > 2);
      }
    },
    'notice' => sub {
      # Filehandle, Where, What.
      my @lines = split /\n/, $_[2];
      for(@lines) {
        if(/^\s*?$/) { next; }
        lkRaw($_[0],"NOTICE $_[1] :".&{$lk{plugin}{'Fancify'}{utilities}{main}}($_,($lk{data}{plugins}{'Fancify'}{$_[1]})?$lk{data}{plugins}{'Fancify'}{$_[1]}:($lk{data}{plugins}{'Fancify'}{colors})?$lk{data}{plugins}{'Fancify'}{colors}:0));
        select(undef, undef, undef, 0.25) if(@lines > 2);
      }
    },
    'action' => sub {
      # Filehandle, Where, What.
      lkRaw($_[0],"PRIVMSG $_[1] :\x01ACTION ".&{$lk{plugin}{'Fancify'}{utilities}{main}}($_[2])."\x01");
    },
    'part' => sub {
      # Filehandle, Where, What.
      lkRaw($_[0],"PART $_[1] :".&{$lk{plugin}{'Fancify'}{utilities}{main}}($_[2]));
    }
  }
});