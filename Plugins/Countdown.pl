addPlug("Count", {
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'Countdown',
  'dependencies' => ['Core_Utilities'],
  'utilities' => {
    'down' => sub {
      # Input: Handle, Channel, Comic ID.
      my @a = @{$_[1]}; 
      my $handle = &{$utility{'Core_Utilities_getHandle'}}($a[0]);
      my $count = $a[2]-1;
      if($count <= 0) { 
        &{$utility{'Fancify_say'}}($handle,$a[1],">>Go!".(($a[3])?" [\x04".$a[3]."\x04]":'')); 
        if($a[3] && $utility{'MPC_send'} && ($a[1] =~ /TheSync$/i)) {
          $utility{'MPC_send'}({wm_command=>'-1',position=>$a[3]});
          $utility{'MPC_send'}({wm_command=>'887'});
        }
      }
      else {
        &{$utility{'Fancify_say'}}($handle,$a[1],">>$count...");
        addTimer(time+1,{'name'=>'countdown'.$a[0].$a[1],'code'=>$utility{"Count_down"},'args'=>[$a[0],$a[1],$count,$a[3]]});
      }
      return 1;
    }
  },
  'commandsV2' => {
    'Pause' => {
      'description' => "Pauses the synced video",
      'tags' => ['utility'],
      'code' => sub {
        $utility{'Fancify_say'}($_[1],$_[2],'>>Pause!');
        $utility{'MPC_send'}({wm_command=>'888'}) if($utility{'MPC_send'} && ($_[2] =~ /TheSync$/i)); 
      }
    },
    'Countdown' => {
      'description' => "Starts a countdown with the default count of 5.",
      'tags' => ['utility'],
      'code' => sub {
        my $count = 3;
        my $name = 'countdown'.$_[6].$_[2];
        my $caught = 0;
        foreach $time (keys %{$lk{timer}}) { foreach(@{$lk{timer}{$time}}) { $caught = 1 if(${$_}{name} eq $name); } }
        if(!$caught) { addTimer(time+1,{'name'=>$name,'code'=>$utility{"Count_down"},'args'=>[$_[6],$_[2],$count+1,"00:00:00"]}); }
      }
    },
    'Countdown (?<playhead>\d\d:\d\d:\d\d)' => {
      'description' => "Starts a countdown with the default count of 5.",
      'tags' => ['utility'],
      'code' => sub {
        my $count = 3;
        my $name = 'countdown'.$_[6].$_[2];
        my $caught = 0;
        foreach $time (keys %{$lk{timer}}) { foreach(@{$lk{timer}{$time}}) { $caught = 1 if(${$_}{name} eq $name); } }
        if(!$caught) { addTimer(time+1,{'name'=>$name,'code'=>$utility{"Count_down"},'args'=>[$_[6],$_[2],$count+1,$+{playhead}]}); }
      }
    }
  }
});