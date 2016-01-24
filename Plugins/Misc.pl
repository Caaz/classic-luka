addPlug("Caaz_Utilities", {
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Misc utilities',
  'dependencies' => ['Core_Utilities'],
  'modules' => ['HTML::Entities', 'LWP::Simple'],
  'utilities' => {
    'randName' => sub {
      print "$plugin is using Caaz_Utilities_randName! This is deprecated and will be removed soon!\n";
      my $url = 'http://www.behindthename.com/random/random.php?';
      if($_[0]) {
        lkDebug('Using Params');
        my @params;
        foreach(keys %{$_[0]}){ push(@params,"$_=$_[0]{$_}"); }
        $url .= join '&', @params;
      }
      else { lkDebug("Using default."); $url .= 'number=1&gender=both&surname=&all=no&usage_eng=1'; }
      lkDebug($url);
      if(get($url) =~ /\<span class=\"heavyhuge\"\>(.+?)\<\/span\>/is) {
        my $capture = $1;
        my @name;
        while($capture =~ /\<a class=\"plain\".+?\>(.+?)\<\/a\>/g) { push(@name, $1); }
        return decode_entities(join " ", @name);
      }
      return 'NONAME';
    },
  }
});
addPlug("Poll", {
  'name' => "Poll",
  'dependencies' => ['Fancify'],
  'version' => 1,
  'description' => "This plugin is here so that the general users can create polls which other people can vote on. It's great for making up minds and deciding whether rwby is anime.",
  'commands' => {
    # poll open Do you think Luka 4 is awesome? Yes, No
    # return ID.
    # poll Close ID
    # poll vote ID Option
    # poll list
    '^Polls$' => {
      'cooldown' => 5,
      'description' => "Lists available open polls.",
      'code' => sub {
        my $j = 0;
        foreach(@{$_[3]{polls}}) {
          lkDebug(${$_}{creator}.' - '.${$_}{question});
          my $string = ($j+1).": [>>${$_}{creator}] \x04${$_}{question}\x04";
          my $i = 0;
          foreach $answer (@{${$_}{answers}}) {
            $string .= " [${$answer}{text} (\x04${$answer}{votes}\x04)]";
            $i++;
          }
          &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},$string);
          $j++;
        }
        &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"... End of polls listing.");
      }
    },
    '^Poll open (.+?\?) (.+)$' => {
      'description' => "Opens a new poll.",
      'example' => 'Poll open What pokemon do you choose? Bulbasaur, Charmander, Squirtle',
      'code' => sub {
        my %poll = ('creator' => $_[2]{nickname}, 'question' => $1, 'total' => 0);
        if(@{$_[3]{polls}} > 3) { &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"Sorry, too many polls exist!"); return 1; }
        foreach(split /, /, $2) { push(@{$poll{answers}}, {'text' => $_, 'votes' => 0}); }
        push(@{$_[3]{polls}}, \%poll);
        &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"Created poll! Check the poll IDs with \x04polls\x04 and vote with \x04vote PollID Option");
      }
    },
    '^Poll close (\d+)$' => {
      'description' => "Closes a poll that you've created.",
      'code' => sub {
        my $poll = $1;
        $poll--;
        if($_[3]{polls}[$poll]) {
          if($_[3]{polls}[$poll]{creator} =~ /^$_[2]{nickname}$/) {
            &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"Closed poll.");
            delete $_[3]{polls}[$poll];
            @{$_[3]}{polls} = grep(!/^$/i, @{$_[3]}{polls});
          }
        }
        else {
          &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"No poll found with ID >>$poll.");
        }
      }
    },
    '^Vote (\d+) (.+)' => {
      'description' => "Votes for an option on a poll.",
      'example' => "Vote 0 Bulbasaur",
      'code' => sub {
        my ($poll,$option) = ($1,$2);
        $poll--;
        if($_[3]{polls}[$poll]) {
          foreach(@{$_[3]{polls}[$poll]{voted}}) {
            if($_ =~ /$_[2]{host}$/) { &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"You've already voted, >>$_[2]{nickname}."); return 0; }
          }
          if($option =~ /^\d+$/i) {
            $option -= 1;
            if($_[3]{polls}[$poll]{answers}[$option]) {
              push(@{$_[3]{polls}[$poll]{voted}}, $_[2]{host});
              $_[3]{polls}[$poll]{answers}[$option]{votes}++;
              &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"Successfully voted $_[3]{polls}[$poll]{answers}[$option]{text}!");
            }
            else {
              &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"No option found with ID >>".($option+1).".");
            }
          }
          else {
            my $i = 0; my $catch = "NULL";
            foreach(@{$_[3]{polls}[$poll]{answers}}) {
              if(${$_}{text} =~ /^$option/i) {
                $catch = $i;
                last;
              }
              $i++;
            }
            if($catch !~ /NULL/) {
              push(@{$_[3]{polls}[$poll]{voted}}, $_[2]{host});
              $_[3]{polls}[$poll]{answers}[$catch]{votes}++;
              &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"Successfully voted $_[3]{polls}[$poll]{answers}[$catch]{text}!");
            }
            else {
              &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"No option found matching \x04$option\x04.");
            }
          }
        }
        else {
          &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"No poll found with ID >>$poll.");
        }
      }
    },
    '^Polls clear$' => {
      'description' => "Clears all polls.",
      'access' => 3,
      'code' => sub {
        delete $_[3]{polls};
        &{$utility{"Fancify_say"}}($_[1]{irc},$_[2]{where},"Cleared polls.");
      }
    }
  }
});
## Misc Commands is here.
addPlug("Misc_Commands", {
  'creator' => 'Caaz',
  'name' => 'Misc Commands',
  'dependencies' => ['Fancify','Core','Caaz_Utilities'],
  'description' => "This is generally where I throw commands that aren't important/big enough to have their own plugin.",
  'commands' => {
    '^Error$' => {
      cooldown => 2,
      'tags' => ['utility'],
      'code' => sub { &{$utility{'Blah'}}(); }
    },
    '^Topic (.*)$' => {
      'access' => 3,
      'tags' => ['utility'],
      'description' => "Sets the topic, using Luka's Fancify to pretty it up.",
      'code' => sub { lkRaw($_[1]{irc},"TOPIC $_[2]{where} :".&{$utility{'Fancify_main'}}($1)); }
    },
    '^Timer (\d+) (.+)$' => {
      cooldown => 2,
      'tags' => ['misc','utility'],
      'description' => "Issues a timer! Eventually this will be useful.",
      'code' => sub {
        my ($time, $command) = ($1,$2);
        if($command =~ /^say (.+)/i) {
          addTimer(time+$time, {
          'name' => "User Timer",
          'code' => sub {
            my @a = @{$_[1]};
            &{$utility{'Fancify_say'}}(@a);
          },
          'args'=>[$_[1]{irc},$_[2]{where},$1]});
        }
      },
    },
    '^rr$' => {
      cooldown => 2,
      'tags' => ['misc','game'],
      'description' => "Roulette of the russian variety",
      'code' => sub { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},&{sub {(rand() <= 1/6)?"You >>died":"You >>live"}}); }
    },
    '^roll (\d+)$' => {
      cooldown => 2,
      'tags' => ['misc','game'],
      'description' => "Roulette of the russian variety",
      'code' => sub { &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},int($1*rand)+1); }
    },
    '^Say (.+)$' => {
      cooldown => 2,
      'tags' => ['misc'],
      'description' => "Repeats whatever you want it to say.",
      'code' => sub { my $text = $1; $text =~ s/\\x04/\x04/g; &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},$text); }
    },
    '^Action (.+)$' => {
      cooldown => 2,
      'tags' => ['misc'],
      'description' => "Repeats whatever you want it to say, in action form!",
      'code' => sub { &{$utility{'Fancify_action'}}($_[1]{irc},$_[2]{where},$1); }
    },
    '^Piglatin (.+)$' => {
      cooldown => 2,
      'tags' => ['misc'],
      'description' => "Translates text into piglatin.",
      'code' => sub {
        my $pl = $1;
        $pl =~ s/\b(qu|[cgpstw]h|[^\W0-9_aeiou])?([a-z]+)/$1?"$2$1ay":"$2way"/ieg;
        &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},$pl);
      }
    },
  }
});
