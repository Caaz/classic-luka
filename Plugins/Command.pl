addPlug('Commands', {
  'creator' => 'Caaz',
  'version' => '2',
  'name' => 'Command',
  'dependencies' => ['Core_Utilities','Userbase','Fancify'],
  'utilities' => {
    'export' => sub {
      # Input: Nothin!
      # Output: Data hash.
      my %data;
      foreach $plugin (keys %{$lk{plugin}}) {
        foreach $regex (keys %{$lk{plugin}{$plugin}{commandsV2}}) {
          my %command = %{$lk{plugin}{$plugin}{commandsV2}{$regex}};
          #print join "\n", $utility{'Util_debug'}(\%command,$regex); print "\n";
          push(@{$data{$plugin}},{
            access => ($command{access})?$command{access}:0,
            cooldown => ($command{cooldown})?$command{cooldown}:1,
            description => ($command{description})?$command{description}:undef,
            example => ($command{example})?$command{example}:[],
            simple => (split /\s|\W/, $regex)[0],
            parameters => ($command{parameters})?$command{parameters}:[],
            tags => ($command{tags})?$command{tags}:[],
          }) if($command{description});
        }
      }
      $utility{'Util_debugP'}(\%data,"Export");
      return \%data;
    },
  },
  'code' => {
    'irc' => sub {
      # key, handle, raw, split, alias
      if($_[3][1] =~ /^PRIVMSG|NOTICE$/i) {
        my %parsed = %{$lk{plugin}{'Core_Utilities'}{utilities}{parse}(@{$_[3]})};
        my $prefix = $lk{data}{prefix};
        foreach $regex (@{$irc{data}{ignore}}){ if($irc{msg}[0] =~ /$regex/i) { return 1; } }
        if($parsed{where} =~ /^$parsed{nickname}$/i) { $prefix = "(?:$lk{data}{prefix})?"; }
        if($parsed{msg} =~ /^$prefix(.+)$/i) {
          my $text = $1;
          foreach $plugin (keys %{$lk{plugin}}) {
            foreach $regex (keys %{$lk{plugin}{$plugin}{commandsV2}}) {
              if($text =~ /^$regex$/i) {
                #print "COMMAND $parsed{nickname}: $text\n";
                my %command = %{$lk{plugin}{$plugin}{commandsV2}{$regex}};
                my $simple = (split /\s|\W/, $regex)[0];
                next if(
                  # Check if it's disabled in this channel.
                  (($lk{data}{plugin}{$_[0]}{settings}{$_[4]}{$parsed{where}}{disable}) && ($simple ~~ @{$lk{data}{plugin}{$_[0]}{settings}{$_[4]}{$parsed{where}}{disable}})) ||
                  # Check if the user still has cooldown.
                  (($lk{tmp}{plugin}{$_[0]}{cooldown}{$_[4]}{$parsed{username}}{$simple}) && ($lk{tmp}{plugin}{$_[0]}{cooldown}{$_[4]}{$parsed{username}}{$simple} >= time))
                );
                # Check if this command requires more access than the user has.
                if($command{access}) {
                  my %account = %{$utility{'Userbase_info'}($_[4],$parsed{nickname})};
                  print "Checking $account{access} to $command{access}\n";
                  unless(($account{access}) && ($account{access} >= $command{access})) {
                    my @levels = ('User','Trusted','Mod','Admin');
                    &{$utility{'Fancify_notice'}}($_[1],$parsed{nickname},"$parsed{nickname}, you don't have enough >>access for this command. (\x04$levels[$command{access}]\x04)");
                    next;
                  }
                }
                # Set cooldown.
                $lk{tmp}{plugin}{$_[0]}{cooldown}{$_[4]}{$parsed{username}}{$simple} = time + (($command{cooldown})?$command{cooldown}:0);
                # Execute!
                eval { 
                  $command{code}(
                    $plugin,            # 0 Plugin key
                    $_[1],              # 1 IRC Handle
                    $parsed{where},     # 2 Channel
                    $parsed{nickname},  # 3 Nickname
                    $parsed{username},  # 4 Username
                    $parsed{host},      # 5 Hostname
                    $_[4],              # 6 Alias
                  ) if $command{code}; };
                $utility{'Fancify_say'}($_[1],$parsed{where},"[>>Error!\x04$plugin\x04\@\x04$simple\x04] $@") if $@;
              }
            }
          }
        }
      }
      return 1;
    },
  }
});