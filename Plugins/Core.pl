addPlug('Core', {
  'creator' => 'Caaz',
  'version' => '2',
  'name' => 'Core',
  'dependencies' => ['Fancify','Core_Utilities'],
  'description' => "This is the newest Core plugin. It covers bot managemeent, and the typical commands that should only be available to the owner.",
  'code' => {
    'irc' => sub {
      my %irc = ('irc' => $_[1], 'raw' => $_[2], 'msg' => $_[3]);
      if($irc{msg}[1] =~ /^invite$/i) {
        if(!($irc{msg}[3] ~~ @{$lk{tmp}{plugin}{'Core'}{badChans}})) {
          push(@{$lk{data}{networks}[$lk{tmp}{connection}{fileno($irc{irc})}]{autojoin}}, $irc{msg}[3]);
          lkRaw($irc{irc},"JOIN $irc{msg}[3]");
          &{$utility{'Fancify_say'}}($irc{irc}, $irc{msg}[3], "[Invited by \x04".(split /\!/, $irc{msg}[0])[0]."\x04] This channel has been added to >>autojoin. Kick me to remove it. Commands begin with $lk{data}{prefix}");
        }
        else { $utility{'Fancify_say'}($irc{irc},(split /\!/, $irc{msg}[0])[0],"Sorry, $irc{msg}[3] can't be joined right now. Contact the owner if you want me back."); }
      }
      elsif($irc{msg}[1] =~ /^kick$/i) {
        if($irc{msg}[3] =~ /^$lk{data}{networks}[$lk{tmp}{connection}{fileno($irc{irc})}]{nickname}$/i) {
          push(@{$lk{tmp}{plugin}{'Core'}{badChans}}, $irc{msg}[2]);
          @{$lk{data}{networks}[$lk{tmp}{connection}{fileno($irc{irc})}]{autojoin}} = grep(!/^$irc{msg}[2]$/i, @{$lk{data}{networks}[$lk{tmp}{connection}{fileno($irc{irc})}]{autojoin}});
        }
      }
    }
  },
  'utilities' => {
    'pluginAll' => sub {
      # Input: What
      foreach(keys %{$lk{plugin}}) { &{$lk{plugin}{$_}{code}{$_[0]}}({'data' => $lk{data}{plugin}{$_}, 'tmp' => $lk{tmp}{plugin}{$_}}) if($lk{plugin}{$_}{code}{$_[0]}); }
      return 1;
    },
    'restart' => sub { exec('perl Luka.pl'); },
    'reload' => sub {
      # Input: Type
      # 0 : Only load new plugins
      # 1 : Load all plugins
      my $startTime = time;
      if(!$_[0]) { &{$utility{'Core_pluginAll'}}('unload'); }
      elsif($_[0] == 1) { lkUnloadPlugins(); }
      return {'time'=>(time-$startTime),'errors' => lkLoadPlugins()};
    },
    'reloadSay' => sub {
      # Input: Handle, Where, Type
      my %return = %{&{$utility{'Core_reload'}}($_[2])};
      &{$utility{'Fancify_say'}}($_[0],$_[1],"Reloaded. [>>$return{time} ".&{$utility{'Core_Utilities_pluralize'}}("second", $return{time})."] [>>".@{$return{errors}}.' '.&{$utility{'Core_Utilities_pluralize'}}("error", @{$return{errors}})."]");
      foreach(@{$return{errors}}) {
        my @msg = split /\n/, ${$_}{message};
        @msg = grep !/^\s+?$/, @msg;
        &{$utility{'Fancify_say'}}($_[0],$_[1],"[\x04${$_}{plugin}\x04] ".$msg[0]);
      }
      return 1;
    },
    'getNetworks' => sub {
      # Input: None
      # Output: Array of network
      my @output = @{$lk{data}{networks}};
      foreach(@output) { if(&{$utility{'Core_Utilities_getHandle'}}(${$_}{name})) { ${$_}{connected} = 1; } }
      return \@output;
    },
    'getNetworkString' => sub {
      # Input: Network Hash, Type
      # Output: True if success
      # 0: Short
      # 1: Long
      my $string = '';
      my %network = %{$_[0]};
      if(!$_[1]) {
        return "\x04$network{name}\x04" if(($network{connected}) && (!$network{disabled}));
        return "$network{name}" if((!$network{connected}) || ($network{disabled}));
      }
      elsif($_[1] == 1) {
        if($network{connected}) {
          return "[\x04$network{name}\x04] [Disabled] [$network{host}:$network{port}] [>>".(@{$network{autojoin}}).&{$utility{'Core_Utilities_pluralize'}}(' autojoin', @{$network{autojoin}}+0).".]" if($network{disable});
          return "[\x04$network{name}\x04] [>>Enabled] [$network{host}:$network{port}] [>>".(@{$network{autojoin}}).&{$utility{'Core_Utilities_pluralize'}}(' autojoin', @{$network{autojoin}}+0).".]" if(!$network{disable});
        }
        else {
          return "[$network{name}] [Disabled] [$network{host}:$network{port}] [>>".(@{$network{autojoin}}).&{$utility{'Core_Utilities_pluralize'}}(' autojoin', @{$network{autojoin}}+0).".]" if($network{disable});
          return "[$network{name}] [>>Enabled] [$network{host}:$network{port}] [>>".(@{$network{autojoin}}).&{$utility{'Core_Utilities_pluralize'}}(' autojoin', @{$network{autojoin}}+0).".]" if(!$network{disable});
        }
      }
      return 0;
    },
    'showNetworks' => sub {
      # Input: Handle, Where, Type
      # 0: Short
      # 1: Long
      my @networks = @{&{$utility{'Core_getNetworks'}}};
      if(!$_[2]) {
        my @output = ();
        my $i = 0;
        foreach(@networks) { push(@output,"[>>$i: ".&{$utility{'Core_getNetworkString'}}($_,$_[2])."]"); $i++; }
        &{$utility{'Fancify_say'}}($_[0],$_[1],join " ", @output);
      }
      else {
        my $i = 0;
        foreach(@networks) { &{$utility{'Fancify_say'}}($_[0],$_[1],">>$i: ".&{$utility{'Core_getNetworkString'}}($_,$_[2])); $i++; }
      }
      return 1;
    },
    'getAllPlugins' => sub {
      # Input: None
      # Output: An array of plugins, sorted by name, filled with info!
      my %output;
      foreach $plug (keys %{$lk{plugin}}) {
        my %plugin = (key=>$plug);
        foreach('name','creator','version','description') { $plugin{$_} = $lk{plugin}{$plug}{$_} if($lk{plugin}{$plug}{$_}); }
        if(!$lk{data}{disablePlugin}{$plug}) { push(@{$output{loaded}}, \%plugin); }
        else { push(@{$output{unloaded}}, \%plugin); }
      }
      foreach $load ('loaded','unloaded') { @{$output{$load}} = sort { lc(${$a}{key}) cmp lc(${$b}{key}) } @{$output{$load}}; }
      return \%output;
    },
    'getPluginString' => sub {
      # Input: Plugin, Type
      # 0: Short
      my %plugin = %{$_[0]};
      my $type = $_[1];
     # &{$utility{'Core_Utilities_debugHash'}}(\%plugin);
      my $string = '';
      if((!$type) || ($type == 0)) {
        $string .= "[\x04$plugin{key}\x04]";
      }
      return $string;
    },
    'showPlugins' => sub {
      # Input: Handle, Where, type
      my %plugins = %{&{$utility{'Core_getAllPlugins'}}};
      my @output;
      if((!$_[2]) || ($_[2] == 0)) {
        &{$utility{'Fancify_say'}}($_[0],$_[1],">>".@{$plugins{loaded}}." plugins loaded.");
        foreach(@{$plugins{loaded}}) { push(@output, &{$utility{'Core_getPluginString'}}($_,0)); }
      }
      else {
        &{$utility{'Fancify_say'}}($_[0],$_[1],">>".@{$plugins{unloaded}}." plugins not loaded.");
        foreach(@{$plugins{unloaded}}) { push(@output, &{$utility{'Core_getPluginString'}}($_,0)); }
      }
      my $string = '';
      foreach(@output) {
        $string .= $_.' ';
        if((split //, $string) > 300) { &{$utility{'Fancify_say'}}($_[0],$_[1],$string); $string = ''; }
      }
      if($string !~ /^$/) { &{$utility{'Fancify_say'}}($_[0],$_[1],$string); }
      return 1;
    },
    'setPluginDisabled' => sub {
      # Input : Plugin Key, true/false
      # Output : Plugin key name if succeeded, 0 if nothing.
      my $output = 0;
      foreach $plug (keys %{$lk{plugin}}) { lkDebug("Checking $plug against $_[0]"); if($plug =~ /^$_[0]$/i) { lkDebug('disabled'); $output = 1; $lk{data}{disablePlugin}{$plug} = $_[1]; } }
      return $output;
    }
  },
  'commandsV2' => {
    '\!(?<code>.+)' => {
      access => 3,
      description => "Evaluates some code",
      code => sub {
        my @result = split /\n|\r/, eval $+{code};
        if($@) { lkRaw($_[1],"PRIVMSG $_[2] :".(join "\|", split /\r|\n/, $@)); }
        else { lkRaw($_[1],"PRIVMSG $_[2] :".(join "\|", @result)); }
      },
    },
  },
  'commands' => {
    '^End$' => {
      'tags' => ['utility'],
      'description' => "Closes Luka.",
      'access' => 3,
      'code' => \&lkEnd
    },
    '^Reload$' => {
      'description' => "Reloads any new code added to plugins.",
      'tags' => ['utility'],
      'cooldown'=>1,
      'access' => 3,
      'code' => sub { &{$utility{'Core_reloadSay'}}($_[1]{irc},$_[2]{where},0); }
    },
    '^Refresh$' => {
      'description' => "Reloads all plugins.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub { &{$utility{'Core_reloadSay'}}($_[1]{irc},$_[2]{where},1); }
    },
    '^Restart$' => {
      'description' => "Restarts the entire bot.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub { &{$utility{'Core_restart'}}(); }
    },
    '^Plugins (Un)?loaded$' => {
      'description' => "Lists all Loaded or Unloaded plugins.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub { my $un = $1; my $type = 0; $type = 1 if($un); &{$utility{'Core_showPlugins'}}($_[1]{irc},$_[2]{where},$type); }
    },
    '^Plugins (Disable|Enable) (.+)$' => {
      'description' => "Disables or Enables a list of plugins by key.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub {
        my $command = lc $1;
        my $type = 0; $type = 1 if($command eq 'disable');
        my @keys = split /\s+/, $2;
        my $count = 0;
        foreach(@keys) { $count += &{$utility{'Core_setPluginDisabled'}}($_,$type); }
        if($count) {
          &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},">>$count ".&{$utility{'Core_Utilities_pluralize'}}('plugin', $count).' '.$command.'d. >>Refreshing...');
          &{$utility{'Core_reloadSay'}}($_[1]{irc},$_[2]{where},1);
        }
        else { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},'No plugins affected.'); }
      }
    },
    '^Networks (.+)$' => {
      'description' => "Lists, disables, or enables networks.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub {
        my $command = $1;
        if($command =~ /^list( long)?$/i) {
          my $type = $1;
          &{$utility{'Core_showNetworks'}}($_[1]{irc},$_[2]{where},1) if(($type) && ($type =~ /long$/i));
          &{$utility{'Core_showNetworks'}}($_[1]{irc},$_[2]{where}) if((!$type) || ($type =~ /^$/));
        }
        elsif($command =~ /^(en|dis)able (.+)$/i) {
          my ($what,$target) = ($1,$2);
          my @type = ('Enabled');
          if($what =~ /^d/i) { @type = ('Disabled',1); }
          if($lk{data}{networks}[$target]) {
            if($type[1]) { lkDebug("Disabling."); $lk{data}{networks}[$target]{disable} = 1; }
            else { delete $lk{data}{networks}[$target]{disable}; }
            &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},">>$type[0] network \x04$lk{data}{networks}[$target]{name}\x04");
            # Disconnect/connect code?
            lkSave();
          }
          else {
            &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"No network with that >>ID.");
          }
        }
      }
    },
    '^Announce (.+)$' => {
      'description' => "Announces to all of the bot's channels.",
      'tags' => ['utility'],
      'access' => 3,
      'code' => sub { my $msg = $1; foreach(@{$lk{data}{networks}[$lk{tmp}{connection}{fileno($_[1]{irc})}]{autojoin}}) { &{$utility{'Fancify_say'}}($_[1]{irc},$_,$msg); } }
    },
    '^Autojoin (.+)' => {
      'tags' => ['utility'],
      'description' => "Add, Del, or List Autojoins.",
      'access' => 2,
      'code' => sub {
        my $command = $1;
        my @autojoin = sort @{$lk{data}{networks}[$lk{tmp}{connection}{fileno($_[1]{irc})}]{autojoin}};
        if($command =~ /^list$/i) { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"[".(join "] [", @autojoin)."]"); }
        elsif($command =~ /^add (\#.+)$/i) { 
          my @channels = split /,\s*/, $1; 
          push(@autojoin, @channels); 
          foreach(@channels) { lkRaw($_[1]{irc},"JOIN :$_"); }
          &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"Added [".(join "] [", @channels)."] to autojoin.");
        }
        elsif($command =~ /^del (.+)$/i) {
          my $regex = $1;
          my @removed = grep(/$regex/i, @autojoin);
          @autojoin = grep(!/$regex/i, @autojoin);
          foreach(@removed) { &{$utility{'Fancify_part'}}($_[1]{irc},$_,"Removed $_ from autojoin."); }
          &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"Removed >>".@removed." ".&{$utility{'Core_Utilities_pluralize'}}('channel', @removed+0)." matching [\x04/\x04\x04$regex\x04\x04/i\x04]");
        }
        else { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"You're doing something wrong. Autojoin commands are >>Add #Channel, >>Del #Channel, or >>List"); }
        @autojoin = &{$utility{'Core_Utilities_uniq'}}(@autojoin);
        @{$lk{data}{networks}[$lk{tmp}{connection}{fileno($_[1]{irc})}]{autojoin}} = @autojoin;
      }
    },
    '^Ignore (.+)' => {
      'tags' => ['utility'],
      'description' => "Add, Del, or List ignores.",
      'access' => 2,
      'code' => sub {
        my $command = $1;
        my @ignore = sort @{$lk{data}{plugin}{"Core_Ignore"}{ignore}};
        if($command =~ /^list$/i) { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"[\x04".(join "\x04] [\x04", @ignore)."\x04]"); }
        elsif($command =~ /^add (.+)$/i) { 
          my @ignores = split /,\s*/, $1; 
          push(@ignore, @ignores); 
          &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"Added [\x04".(join "\x04] [\x04", @ignores)."\x04] to ignores.");
        }
        elsif($command =~ /^del (.+)$/i) { 
          my ($string,$position) = ($1,0); my @catch = ();
          foreach $regex (@ignore){ if($string =~ /$regex/i) { push(@catch, $position); } $position++; }
          foreach(@catch) { delete $ignore[$_]; }
          &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"Removed >>".(@catch+0)." ".&{$utility{'Core_Utilities_pluralize'}}('ignore', @catch+0)." matching \x04$string\x04");
        }
        else { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"You're doing something wrong. Ignore commands are >>Add >>regex, >>Del >>string, or >>List"); }
        @ignore = &{$utility{'Core_Utilities_uniq'}}(grep !/^$/, @ignore);
        @{$lk{data}{plugin}{"Core_Ignore"}{ignore}} = @ignore;
      }
    }
  }
});
addPlug('Core_Ignore', {
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Core Ignore',
  'description' => "This plugin sets up a way to ignore problem users.",
  'dependencies' => ['Core_Utilities'],
  'code' => {
    'pre' => sub {
      my %irc = ('irc' => $_[1], 'raw' => $_[2], 'msg' => $_[3]);
      if($irc{msg}[1] =~ /^PRIVMSG|NOTICE$/i) {
        my %parsed = %{&{$lk{plugin}{'Core_Utilities'}{utilities}{parse}}(@{$irc{msg}})};
        my $network = $lk{data}{networks}[$lk{tmp}{connection}{fileno($irc{irc})}]{name};
        foreach $regex (@{$irc{data}{ignore}}){ if($irc{msg}[0] =~ /$regex/i) { return 1; } }
        return 0;
      }
      else { return 0; }
    }
  }
});
addPlug('Core_Command', {
  'creator' => 'Caaz',
  'version' => '1.1',
  'name' => 'Core Command',
  'dependencies' => ['Core_Utilities','Userbase','Fancify'],
  'code' => {
    'irc' => sub {
      # key, handle, raw, parsed.
      my %irc = ('irc' => $_[1], 'raw' => $_[2], 'msg' => $_[3]);
      if($irc{msg}[1] =~ /^PRIVMSG|NOTICE$/i) {
        my %parsed = %{&{$lk{plugin}{'Core_Utilities'}{utilities}{parse}}(@{$irc{msg}})};
        my $network = $lk{data}{networks}[$lk{tmp}{connection}{fileno($irc{irc})}]{name};
        my $prefix = $lk{data}{prefix};
        if($parsed{where} =~ /^$parsed{nickname}$/i) { $prefix = "(?:$lk{data}{prefix})?"; }
        if($parsed{msg} =~ /^$prefix(.+)$/i) {
          my $com = $1;
          foreach $plugin (keys %{$lk{plugin}}) {
            foreach $regex (keys %{$lk{plugin}{$plugin}{commands}}) {
              if($com =~ /$regex/i) {
                lkDebug("Core_Command is eprecated, yet being used at $plugin.");
                my %command = %{$lk{plugin}{$plugin}{commands}{$regex}};
                if($command{cooldown}) {
                  if(($lk{tmp}{plugin}{'Core_Command'}{cooldown}{$parsed{username}}{$regex}) && ($lk{tmp}{plugin}{'Core_Command'}{cooldown}{$parsed{username}}{$regex} > time)) { return 1; }
                  else { $lk{tmp}{plugin}{'Core_Command'}{cooldown}{$parsed{username}}{$regex} = time + $lk{plugin}{$plugin}{commands}{$regex}{cooldown}; }
                }
                eval {
                  if($command{access}) {
                    my %account = %{$utility{'Userbase_info'}($network,$parsed{nickname})};
                    if(($account{access}) && ($account{access} >= $command{access})) {
                      &{$command{code}}($network,\%irc,\%parsed,$lk{data}{plugin}{$plugin},$lk{tmp}{plugin}{$plugin}) if($command{code});
                    }
                    else { &{$utility{'Fancify_say'}}($irc{irc},$parsed{where},"You don't have enough >>access for this command."); }
                  }
                  else { &{$command{code}}($network,\%irc,\%parsed,$lk{data}{plugin}{$plugin},$lk{tmp}{plugin}{$plugin}) if($command{code}); }
                };
                if($@) {
                  &{$utility{'Fancify_say'}}($irc{irc},$parsed{where},"[>>Error!\x04$plugin\x04\@\x04/$regex/i\x04] $@");
                }
              }
            }
          }
        }
      }
    },
  }
});
addPlug('Core_CTCP', {
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Core CTCP',
  'dependencies' => ['Core_Utilities'],
  'code' => {
    'irc' => sub {
      my %irc = ('irc' => $_[1], 'raw' => $_[2], 'msg' => $_[3]);
      if($irc{msg}[1] =~ /^PRIVMSG$/i) {
        my %parsed = %{&{$lk{plugin}{'Core_Utilities'}{utilities}{parse}}(@{$irc{msg}})};
        if($parsed{msg} =~ /^\x01(.+)\x01$/i) {
          my $ctcp = $1;
          if($ctcp =~ /^VERSION$/i) { lkRaw($irc{irc},"NOTICE $parsed{nickname} :\x01VERSION $lk{version} ($lk{os})\x01"); }
          elsif($ctcp =~ /^TIME$/i) { lkRaw($irc{irc},"NOTICE $parsed{nickname} :\x01TIME ".localtime."\x01"); }
          elsif($ctcp =~ /^FINGER$/i) { lkRaw($irc{irc},"NOTICE $parsed{nickname} :\x01FINGER Oh god yes\x01"); }
          elsif($ctcp =~ /^PING$/i) { lkRaw($irc{irc},"NOTICE $parsed{nickname} :\x01PING PONG\x01"); }
        }
      }
    }
  }
});
addPlug('Core_Utilities',{
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Core Utilities',
  'code' => {
    'load' => sub {
      %utility = ();
      # Throw all utilities into %utilities!
      foreach $plugin (keys %{$lk{plugin}}) {
        foreach $utilityName (keys %{$lk{plugin}{$plugin}{utilities}}) {
          $utility{$plugin.'_'.$utilityName} = $lk{plugin}{$plugin}{utilities}{$utilityName};
        }
      }
    }
  },
  'utilities' => {
    'pluralize' => sub {
      # Input: Word, count.
      my $word = $_[0];
      if((!$_[1]) || ($_[1] >= 2)) {
        if($word =~ /[^aeiou]y$/) { $word =~ s/y$/ies/; }
        elsif($word =~ /s$/) { return $word; }
        else { $word .= 's'; }
      }
      return $word;
    },
    'uniq' => sub { my %seen; grep !$seen{$_}++, @_ }, # I can't take any credit for this, but it is fucking beautiful.
    'debugHash' => sub {
      # Input: \%hash;
      my %hash = %{ shift(); };
      lkDebug("DEBUG");
      my @keys = keys %hash; @keys = sort @keys;
      foreach(@keys) { lkDebug("$_ => $hash{$_}"); }
    },
    'parse' => sub {
      # Input: @Msg
      # Output: nickname, username, host, msg, where
      my %return;
      ($return{nickname}, $return{username}, $return{host}) = split/\!|\@/, $_[0];
      $return{where} = ($_[2] =~ /^\#/)? $_[2] : $return{nickname};
      ($return{msg} = $_[3]) =~ s/\003\d{1,2}(?:\,\d{1,2})?|\02|\017|\003|\x16|\x09|\x13|\x0f|\x15|\x1f//g;
      chomp($return{msg});
      return \%return;
    },
    'getHandle' => sub {
      # Get Handle from network name.
      # Input -> Network name
      foreach(keys %{$lk{tmp}{connection}}) {
        if($lk{data}{networks}[$lk{tmp}{connection}{$_}]{name} =~ /^$_[0]$/i) {
          return $lk{tmp}{filehandles}{$_};
        }
      }
      return 0;
    },
    'getTime' => sub {
      # time
      # days, hours, minutes, seconds.
      my ($rem, $days, $hours, $minutes);
      $days = int($_[0]/86400);
      $rem = $_[0]%86400;
      $hours = int($rem/3600);
      $rem = $rem%3600;
      $minutes = int($rem/60);
      $rem = $rem%60;
      my $string;
      $string = "$days ".$utility{'Core_Utilities_pluralize'}("Day",$days)." " if $days;
      foreach($hours,$minutes,$rem) { $_ = "0$_" if((split //, $_) == 1); }
      $string .= "$hours:$minutes:$rem";
      return [$days,$hours,$minutes,$rem,$string];
    },
    'list' => sub {
      # Input: Array
      # Output: String of stuff in fancy list version.
      my @output;
      while (@_ > 1) { push(@output, "[".shift().": \x04".shift()."\x04]"); }
      return join " ", @output;
    },
    'shuffle' => sub { my $deck = shift; return unless @$deck; my $i = @$deck; while (--$i) { my $j = int rand ($i+1); @$deck[$i,$j] = @$deck[$j,$i]; } }
  }
});
addPlug('Core_Get',{
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Lazy Updates',
  'dependencies' => ['Fancify','Core_Utilities'],
  'modules' => ['LWP::Simple'],
  'description' => "Grabs plugins from the github repository and reloads it.",
  'commands' => {
    '^Get (\w+)$' => {
      'access' => 3,
      'description' => "Grab something from the main Github repository.",
      'code' => sub {
        my $plugin = $1;
        my $result = getstore("https://raw.githubusercontent.com/Caaz/Luka/master/Plugins/$plugin.pl","./Plugins.Local/$plugin.pl");
        if($result == 200) {
          $utility{'Fancify_say'}($_[1]{irc},$_[2]{where},"Success! Saved to local plugins. Reloading...");
          $utility{'Core_reloadSay'}($_[1]{irc},$_[2]{where},0);
        }
        else { $utility{'Fancify_say'}($_[1]{irc},$_[2]{where},"Nothing! >>$result!"); }
      }
    },
  },
});