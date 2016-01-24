# Trainer Modes
# 0 - Idle
# 1 - Battle
# 2 - Trade

addPlug("Pokemon", {
  creator => "Caaz",
  version => 2.1,
  name => "Pokemon",
  description => "Just a game. With Pokemon.",
  utilities => {
    ###################
    ## New Routines! ##
    ###################
    res => {
      export => "~/Dropbox/Public/Dev/pkmn/trainer/",
      debug => 1,
    },
    loadDB => sub {
      print "Loading Pokemon database.\n";
      delete $lk{tmp}{plugin}{'Pokemon'}{db};
      open FILE, "<./Resources/pkmn.json";
      my $json = join "", <FILE>;
      close FILE;
      %{$lk{tmp}{plugin}{'Pokemon'}{db}} = %{decode_json($json)};
    },
    saveDB => sub {
      print "Saving Pokemon database.\n";
      open FILE, ">./Resources/pkmn.json";
      print FILE encode_json($lk{tmp}{plugin}{'Pokemon'}{db});
      close FILE;
    },
    ###################
    ## Old Routines! ##
    ###################
    exportTrainer => sub {
      # Input : Trainer
      # Output:
      my $trainer = shift;
      $$trainer{export}=time;
      open FILE, ">../../Dropbox/Public/Dev/pkmn/trainer/".$$trainer{UBID}.".json";
      print FILE encode_json($trainer);
      close FILE;
      return 1;
    },
    findOT => sub {
      # I : OT Array
      # R : Trainer
      my $OT = shift;
      my $trainers = $lk{data}{plugin}{'Pokemon'}{trainer};
      return $$trainers{$OT};
      return (name=>"ERROR");
    },
    checkEvolution => sub {
      # I : Trainer, Pokemon
      # O : Hash. result, msg
      my ($trainer, $pokemon,$traded) = (shift,shift,shift);
      my %result = (msg=>[],result=>0);
      if($$pokemon{held} =~ /^206$/i) { return \%result; }
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn};
      my @potentials = ();
      push(@potentials, @{ $utility{'Util_find'}($db,'evolves_from_species_id','^'.$$pokemon{ID}.'$') });
      #print "I got : ".(join ", ", @potentials)."\n";
      foreach $id (@potentials) {
        my $evo = $$db{$id}{evolution};
        if(($$evo{evolution_trigger_id} == 1) || ($$evo{evolution_trigger_id} == 3)) {
          next if(($$evo{minimum_level}) && ($$evo{minimum_level} > $utility{'Pokemon_getLevel'}($pokemon)));
          next if(($$evo{minimum_happiness}) && (255 > $$pokemon{happiness}));
          print "Checking gender for $id";
          next if(($$evo{gender_id}) && ($$evo{gender_id} != $$pokemon{gender}));
          print "We good";
          next if(($$evo{held_item_id}) && ((!$$pokemon{held}) || ($$evo{held_item_id} != $$pokemon{held})));
          next if(($$evo{trigger_item_id}) && ((!$$pokemon{held}) || ($$evo{trigger_item_id} != $$pokemon{held})));
          foreach $trig ('held_item_id','trigger_item_id') { if(($$evo{$trig}) && ($$evo{$trig} == $$pokemon{held})) { $$pokemon{held}=0; } }

          push(@{$result{msg}},"Hm? \x04".$utility{'Pokemon_getNick'}($pokemon)."\x04 has evolved into... \x04$$db{$id}{name}\x04!");
          foreach $t (@{ $$db{$id}{type} }) { push(@{ $$pokemon{type} }, $t) if(!($t~~@{ $$pokemon{type} })); }
          $$pokemon{ID} = $id;
        }
        elsif(($$evo{evolution_trigger_id} == 2) && ($traded == 1)) {
          next if(($$evo{held_item_id}) && ((!$$pokemon{held}) || ($$evo{held_item_id} != $$pokemon{held})));
          next if(($$evo{gender_id}) && ($$evo{gender_id} == $$pokemon{gender}));
          if(($$evo{held_item_id}) && ($$evo{held_item_id} == $$pokemon{held})) { $$pokemon{held}=0; }
          #return \%result if(@{ $$trainer{ID} } ~~ @{ $$pokemon{OT} });
          push(@{$result{msg}},"Hm? \x04".$utility{'Pokemon_getNick'}($pokemon)."\x04 has evolved into... \x04$$db{$id}{name}\x04!");
          foreach $t (@{ $$db{$id}{type} }) { push(@{ $$pokemon{type} }, $t) if(!($t~~@{ $$pokemon{type} })); }
          $$pokemon{ID} = $id;
        }
      }
      return \%result;
    },
    getEXPfromLevel => sub {
      # Input: growth_rate, Level
      # Return: EXP
      my ($gr,$lv) = (shift,shift);
      $lv = 1 if($lv<1);
      my $exp = $lk{tmp}{plugin}{'Pokemon'}{db}{exp};
      return $$exp{$gr}[$lv-1]+1;
    },
    getLevelfromEXP => sub {
      # Input: growth_rate, EXP
      # Return: EXP
      my ($rate,$experience) = (shift,shift);
      #print "My rate is $rate and experience is $experience\n";
      my $exp = $lk{tmp}{plugin}{'Pokemon'}{db}{exp};
      my $level = 1;
      foreach $xp (@{ $$exp{ $rate }} ) {
        if($xp >= $experience) { last; }
        $level++;
      }
      return 100 if($level > 100);
      return $level;
    },
    getLevel => sub {
      #Input: Pokemon
      my $pokemon = shift;
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn};
      return $utility{'Pokemon_getLevelfromEXP'}($$db{$$pokemon{ID}}{growth_rate_id},$$pokemon{exp});
    },
    getPokemon => sub {
      # Return a pokemon object!
      # Input: MinLevel
      my $id = 0;
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn};
      my @blacklist = ();
      @blacklist = (144..146,150,151,243..245,249..251,377..386,480..494,638..649,716..721) unless(($_[0]>70) && (.2>rand));
      while($id = int(1+721*rand)) { if(!$$db{$id}{evolves_from_species_id}) { last unless($id ~~ @blacklist); }; }
      my @type = @{$$db{$id}{type}};
      my %pokemon = (
        'ID' => $id,
        'exp' => $utility{'Pokemon_getEXPfromLevel'}($$db{$id}{growth_rate_id},int((($_[0])?$_[0]:2) + rand 5)),
        'shiny' => (.005>rand)?1:0,
        'EV' => [0,0,0,0,0,0],
        'IV' => [int rand 32,int rand 32,int rand 32,int rand 32,int rand 32,int rand 32],
        'damage' => 0,
        'OT' => ['00000','00000'],
        'gender' => ($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$id}{gender_rate}==-1)?'0':($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$id}{gender_rate}<rand 8)?'2':'1',
        'type' => \@type,
        'held' => 0,
        'happiness' => 0,
      );
      $utility{'Pokemon_checkEvolution'}(undef,\%pokemon,0);
      $utility{'Pokemon_checkEvolution'}(undef,\%pokemon,0);
      #$utility{'Util_debugP'}(\%pokemon);
      return \%pokemon;
    },
    genFullAccount => sub {
      my $tr = {
        currently=>"Caaz",
        name=>"Red",
        active=>0,
        cash=>500,
        ID=>[10000 + int rand 89999,10000 + int rand 89999],
        UBID=>"-1",
        mode=>0,
        items=>[],
        party=>[],
        PC=>[],
        };
      $utility{'Pokemon_awardItem'}($tr,1,1);
      $utility{'Pokemon_awardItem'}($tr,4,13);
      $utility{'Pokemon_awardItem'}($tr,3,13);
      push(@{ $$tr{'party'} },$utility{'Pokemon_genPokemon'}(int rand 50,1));
      foreach(1..721) { push(@{ $$tr{'PC'} },$utility{'Pokemon_genPokemon'}(int rand 50,$_)); }
      return $tr;
    },
    genPokemon => sub {
      # Return a pokemon object via ID!
      # Input: MinLevel, ID
      my ($level,$id) = (shift,shift);
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn};
      my @type = @{$$db{$id}{type}};
      my @balls = (1,2,3,4,5,6,7,8,9,10,11);
      my %pokemon = (
        'ID' => $id,
        'exp' => $utility{'Pokemon_getEXPfromLevel'}($$db{$id}{growth_rate_id},$level),
        'shiny' => (.005>rand)?1:0,
        'EV' => [0,0,0,0,0,0],
        'IV' => [int rand 32,int rand 32,int rand 32,int rand 32,int rand 32,int rand 32],
        'damage' => 0,
        'OT' => ['00000','00000'],
        'gender' => ($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$id}{gender_rate}==-1)?'0':($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$id}{gender_rate}<rand 8)?'2':'1',
        'type' => \@type,
        'held' => 0,
        'happiness' => 0,
        'caught_in' => $balls[rand(@balls)],
        'level' => $level
      );
      return \%pokemon;
    },
    fixTrainer => sub {
      # I : Acc
      my $acc = shift;
      $utility{'Pokemon_fixItems'}($$acc{trainer});
      $$acc{trainer}{UBID} = $$acc{id};
      $$acc{trainer}{currently} = $$acc{ub}{currently};
      $$acc{trainer}{name} = $$acc{ub}{name};
      foreach $key ('PC','party') { foreach $pkmn (@{$$acc{trainer}{$key}}) {
        #shift(@{ $$pkmn{OT} }) if(@{ $$pkmn{OT} } > 2);
        print "Checking $pkmn\n";
        if(!$$pkmn{ID}) { %{$pkmn} = %{$u{'Pokemon'}{'getPokemon'}(5)}; }
        $$pkmn{level} = $utility{'Pokemon_getLevel'}($pkmn);
        $$pkmn{caught_in} = 4 if(!$$pkmn{caught_in});
        $$pkmn{caught_at} = time if(!$$pkmn{caught_at});
        delete $$pkmn{from} if($$pkmn{from});
        delete $$pkmn{EXP} if($$pkmn{EXP});
        $$pkmn{gender} = ($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pkmn{ID}}{gender_rate}==-1)?'0':($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pkmn{ID}}{gender_rate}<rand 8)?'2':'1' if(!length $$pkmn{gender});
      } }
      return 1;
    },
    trainerInfo => sub {
      # I : Trainer, Type
      # 0 : Small
      my ($trainer, $type) = (shift,shift);
      if($type == 0) {
        return "[$$trainer{UBID} \x04$$trainer{name}\x04: \x04$$trainer{cash}p\x04]";
      }
    },
    getNick => sub {
      # Input: Pokemon
      # Output: String
      if((${$_[0]}{nickname}) && (length ${$_[0]}{nickname})) { return ${$_[0]}{nickname}.((${$_[0]}{shiny}==1)?'*':''); }
      else { return $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{${$_[0]}{ID}}{name}.((${$_[0]}{shiny}==1)?'*':''); }
    },
    addToPC => sub {
      # Input: Trainer, Pokemon
      # Return: PC ID
      my ($trainer,$pokemon) = (shift,shift);
      $$pokemon{damage} = 0;
      return push(@{$$trainer{PC}},$pokemon);
    },
    depositPC => sub {
      # Input: Trainer, PartyID (true)
      # Return: hash result
      # msg : "X was placed into the PC under ID #"
      # result
      # 0 - Failed
      # 1 - Success
      my %result = ();
      my ($trainer,$id) = (shift,shift);
      if($$trainer{party}[$id]) {
        # There's a pokemon in this slot!
        my $pokemon = splice(@{ $$trainer{party} },$id,1);
        %result = (msg=>"\x04".$utility{'Pokemon_getNick'}($pokemon)."\x04 added to slot \x04".($utility{'Pokemon_addToPC'}($trainer,$pokemon))."\x04!",result=>0);
      }
      else { %result = (msg=>"There's no Pokemon in slot \x04".($id+1)."\x04!",result=>0); }
      return \%result;
    },
    fixItems => sub {
      # I : Trainer
      # O : undef
     # return 1;
      my $trainer = shift;
      while(1) {
        my $i = 0;
        my $modified = 0;
        foreach $it (@{ $$trainer{items} }) {
          #print "Item $$it[0] x $$it[1]\n";
          if(($$it[1] < 1) || (!$$it[0])) {
            my $removed = splice(@{ $$trainer{items} },$i,1);
            print "REMOVED $$removed[0] x $$removed[1] from $i\n";
            $modified = 1;
            last;
          }
          $i++;
        }
        if($modified == 0) { last; }
      }
      return 1;
    },
    awardPokemon => sub {
      # I : Trainer, Pokemon
      # O : Hash -> result, @msg
      my ($trainer,$pkmn) = (shift,shift);
      my %result = (msg=>[],result=>1);
      if(@{ $$trainer{party} } < 6) { push(@{ $$trainer{party} },$pkmn); }
      else { push(@{$result{msg}},"\x04".$utility{'Pokemon_getNick'}($pkmn)."\x04 added to PC slot \x04".($utility{'Pokemon_addToPC'}($trainer,$pkmn))."\x04!"); }
      lkSave();
      return \%result;
    },
    whiteout => sub {
      # Input: Trainer
      # Output: result
      my $trainer = shift;
      $$trainer{mode} = 0;
      delete $$trainer{battleID};
      return {msg=>["All of your pokemon have fainted. You rush them to the Pokecenter. ".$utility{'Pokemon_healAllPokemon'}($trainer)],result=>1};
    },
    healAllPokemon => sub {
      # Input: Trainer
      # Output: Message
      my $trainer = shift;
      foreach(@{ $$trainer{party} }) { if(${$_}{ID}) { ${$_}{damage} = 0; } }
      $utility{'Pokemon_setActive'}($trainer);
      return "Your Pokemon are now healed.";
    },
    setActive => sub {
      # Input: Trainer
      # Output: result hash (msg, result)
      my $trainer = shift;
      my %result = ();
      my $id = 0;
      foreach $pkmn (@{$$trainer{party}}) {
        if(($$pkmn{ID}) && ($$pkmn{damage} < $utility{'Pokemon_getStat'}($pkmn,0))) {
          $$trainer{active} = $id;
          %result = (msg=>"Active Pokemon set to \x04".$utility{'Pokemon_getNick'}($pkmn)."\x04",result=>1);
          return \%result;
        }
        $id++;
      }
      %result = (msg=>$ {$utility{'Pokemon_whiteout'}($trainer) }{msg},result=>0);
      return \%result;
    },
    getBaseStats => sub {
      #Input: Pokemon
      my $pokemon = shift;
      return ($lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pokemon{ID}}{stats})?$lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pokemon{ID}}{stats}:[1,1,1,1,1,1];
    },
    getFullStats => sub {
      #Input: Pokemon
      my $pokemon = shift;
      my @stats = @{$lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pokemon{ID}}{stats}};
      my $index = 0;
      foreach $stat (@stats) {
        $stat = int((($$pokemon{IV}[0]+(2*$stat)+$$pokemon{EV}[0]/4+100)*$utility{'Pokemon_getLevel'}($pokemon))/100+10) if($index == 0);
        $stat = int((($$pokemon{IV}[$index] + (2*$stats[$index]) + $$pokemon{EV}[$index]/4) * $utility{'Pokemon_getLevel'}($pokemon))/100+5);
        $index++;
      }
      return \@stats;
    },
    getStat => sub {
      #Input: Pokemon, id
      # 0  HP!
      # 1  Attack,
      # 2  Defense,
      # 3  Sp.Attack
      # 4  Sp.Defense
      # 5  Speed
      if($_[1] == 0) {
        return int(((${$_[0]}{IV}[0]+(2*${$utility{'Pokemon_getBaseStats'}($_[0])}[0])+${$_[0]}{EV}[0]/4+100)*$utility{'Pokemon_getLevel'}($_[0]))/100+10);
      }
      else {
        my @stats = @{$utility{'Pokemon_getBaseStats'}($_[0])};
        return int(((${$_[0]}{IV}[$_[1]] + (2*$stats[$_[1]]) + ${$_[0]}{EV}[$_[1]]/4) * $utility{'Pokemon_getLevel'}($_[0]))/100+5);
      }
    },
    awardItem => sub {
      # Input: Trainer, ItemID, Amount
      # Output: Msg
      my ($trainer,$id,$amount) = (shift,shift,shift);
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{items};
      my $added = 0;
      foreach $i (@{ $$trainer{items} }) { if($$i[0] == $id) { $$i[1]+=$amount; $added = 1; } }
      push(@{ $$trainer{items} },[$id,$amount]) if(!$added);
      return "You got \x04$amount $$db{$id}{name}".(($amount>1)?'s':'')."\x04!";
    },
    getInfo => sub {
      # Input: Pokemon, Type, Prefix
      # 0 : In BattleOpponent's Pokemon
      # 1 : In Battle - Your Pokemon
      # 2 : Short
      # 3 : Shorter (Party)
      # 4 : Very Short (PC)
      # 5 : Very Long (Summary)
      # 6 : Very Very Short (Battle, display whatever with level)
      # Output: Pokemon info
      my ($pkmn,$type,$pre) = (shift,shift,shift);
      my $maxHealth = $utility{'Pokemon_getStat'}($pkmn,0);
      my $currentHealth = $maxHealth - $$pkmn{damage};
      my $percentage = $currentHealth/$maxHealth*100;
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db};
      my @types = ();
      foreach(@{ $$pkmn{type} }) { push(@types, $$db{types}{$_}{name}); }
      my $color = (($percentage>60)?'09':($percentage>20)?'07':($currentHealth>0)?'04':'05');
      if($type == 0) {
        return "[".(($pre)?"$pre ":"")."\cC$color".$utility{'Pokemon_getNick'}($pkmn)." \x04".$utility{'Pokemon_getLevel'}($pkmn)."\x04 ".(join "/", @types)." \cC$color".(int $percentage)."\%\x04\x04]";
      }
      elsif($type == 1) {
        return "[".(($pre)?"$pre ":"")."\cC$color".$utility{'Pokemon_getNick'}($pkmn)." \x04".$utility{'Pokemon_getLevel'}($pkmn)." \cC$color".$currentHealth."/".$maxHealth."\x04]";
      }
      elsif($type == 2) {
        print "Remove this PoS Here\n";
        return "[".(($pre)?"$pre ":"")."\cC$color".$utility{'Pokemon_getNick'}($pkmn)." Lv\x04".$utility{'Pokemon_getLevel'}($pkmn)."\x04".((($currentHealth>0) && ($currentHealth!=$maxHealth))?"\cC$color".(($currentHealth>0)?" ".$currentHealth:0)."/".$maxHealth."\x04\x04":'')."]";
      }
      elsif($type == 3) {
        my $nick = $utility{'Pokemon_getNick'}($pkmn);
        return "[".(($pre)?"$pre ":"")."\cC$color".$nick."\x04\x04".(($nick=~/^$$db{pkmn}{$$pkmn{ID}}{name}.?/)?'':"/\x04$$db{pkmn}{$$pkmn{ID}}{name}\x04")." Lv\x04".$utility{'Pokemon_getLevel'}($pkmn)."\x04".((($currentHealth>0) && ($currentHealth!=$maxHealth))?"\cC$color".(($currentHealth>0)?" ".$currentHealth:0)."/".$maxHealth."\x04\x04":'')."]";
      }
      elsif($type == 4) {
        my $nick = "\x04".$utility{'Pokemon_getNick'}($pkmn)."\x04".(($utility{'Pokemon_getNick'}($pkmn)=~/^$$db{pkmn}{$$pkmn{ID}}{name}.?$/)?'':"/\x04$$db{pkmn}{$$pkmn{ID}}{name}\x04");
        my $level = "Lv\x04".$utility{'Pokemon_getLevel'}($pkmn)."\x04";
        return "[".(($pre)?"$pre ":"")."$nick $level]";
      }
      elsif($type == 5) {
        my $nick = "\x04".$utility{'Pokemon_getNick'}($pkmn)."\x04".(($utility{'Pokemon_getNick'}($pkmn)=~/^$$db{pkmn}{$$pkmn{ID}}{name}.?$/)?'':"/\x04$$db{pkmn}{$$pkmn{ID}}{name}\x04");
        my $level = "Lv\x04".$utility{'Pokemon_getLevel'}($pkmn)."\x04";
        my @genders = ("\cC9No Gender","\cC13Female","\cC2Male");
        my $gender = $genders[ $$pkmn{gender} ]."\x04\x04";
        my @stats = @{$utility{'Pokemon_getFullStats'}($pkmn)};
        shift(@stats);
        my %OT = %{ $utility{'Pokemon_findOT'}($$pkmn{OT}) };
        return "[".(($pre)?"$pre ":"")."$nick $gender $level \cC$color$currentHealth/$maxHealth \x04".(join "\x04/\x04", @types)." ".(join "\x04/\x04", @stats)."\x04 OT:\x04".$OT{name}."\x04".(($$pkmn{held})?" Holding: \x04$$db{items}{$$pkmn{held}}{name}\x04":'')."]";
      }
      elsif($type == 6) {
        my @genders = (''," \cC13F\x04\x04"," \cC2M\x04\x04");
        my $nick = "\x04".$utility{'Pokemon_getNick'}($pkmn)."\x04".(($utility{'Pokemon_getNick'}($pkmn)=~/^$$db{pkmn}{$$pkmn{ID}}{name}.?$/)?'':"/\x04$$db{pkmn}{$$pkmn{ID}}{name}\x04");
        my $level = "Lv\x04".$utility{'Pokemon_getLevel'}($pkmn)."\x04";
        return (($pre)?"$pre ":"")."$nick$genders[ $$pkmn{gender} ] $level";
      }
    },
    newBattle => sub {
      # I: Trainer, Type, @{Pokemon}?
      # 0 : AI Wild
      # 1 : AI Trainer
      # 2 : PvP Open
      # 3 : PvP Private
      # O: Result Hash (msg, result)
      my ($trainer,$type,$pkmn) = (shift,shift,shift);
      my %battle = ();
      my %result = (msg=>[],result=>0);
      if(($type == 0) | ($type == 1)) {
        my %aiTrainer = ('AI'=>1,'ID'=>[1,1],'party'=>$pkmn,'active'=>0,'UBID'=>'-1',cash=>($type==1)?1000*@{$pkmn}:0);
        %battle = (
          trainers => [$trainer,\%aiTrainer],
          type => $type,
        );
        $$trainer{mode} = 1;
        my $battleID = $utility{'Pokemon_placeBattle'}(\%battle);
        # print "My battleID is $battleID\n";
        foreach($$trainer{battleID},$aiTrainer{battleID}) { $_ = $battleID; }
        push(@{$result{msg}},"[\x04Attack\x04]") if(@{ $$trainer{party} });
        push(@{$result{msg}},"[\x04Switch\x04]") if(@{ $$trainer{party} }>1);
        push(@{$result{msg}},"[\x04Item\x04]") if(@{ $$trainer{items} });
      }
      if($type==0) {
        push(@{$result{msg}},"[\x04Run\x04]");
        push(@{$result{msg}},"A wild");
        foreach $k (@{$pkmn}) {
          push(@{$result{msg}},"\x04$lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pkmn[0]{ID}}{name}\x04 Lv\x04".$utility{'Pokemon_getLevel'}($k)."\x04");
        }
        push(@{$result{msg}},"appeared!");
      }
      elsif($type==1) {
        push(@{$result{msg}},"A trainer locked eyes with you! They sent out \x04$lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pkmn[0]{ID}}{name}\x04 Lv\x04".$utility{'Pokemon_getLevel'}($$pkmn[0])."\x04");
      }
      if(($type == 0) | ($type == 1)) {
        push(@{$result{msg}},"You sent out \x04".$utility{'Pokemon_getNick'}($$trainer{party}[$$trainer{active}])."\x04! Lv\x04".$utility{'Pokemon_getLevel'}($$trainer{party}[$$trainer{active}])) if(@{ $$trainer{party} });
      }

      return \%result;
    },
    placeBattle => sub {
      # I: Battle
      # O: battleID
      return push(@{$lk{tmp}{plugin}{'Pokemon'}{battles}},shift);
    },
    getOpponent => sub {
      # I: Trainer
      # O: Other Trainer
      my $trainer = shift;
      if($$trainer{battleID}) {
        if($lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1]) {
          my $battle = $lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1];
          foreach $tr (@{ $$battle{trainers} }) {
            if($$tr{ID} != $$trainer{ID}) { return $tr; }
          }
        }
      }
      print "No Trainer found ERROR\n";
      return undef;
    },
    battleInput => sub {
      # I: Trainer, \%action
      # O: Hash (msg,result)
      ###############################
      # Action Hash                 #
      # type, arg.                  #
      # type                        #
      #   0 : Run     - undef       #
      #   1 : Item    - Item Index  #
      #   2 : Switch  - Party Index #
      #   3 : Attack  - Attack/Type #
      ###############################
      my ($trainer,$action) = (shift,shift);
      my %result = (msg=>["You aren't in a battle."],result=>0);
      if($$trainer{battleID}) {
        if($lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1]) {
          my $battle = $lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1];
          if(!$$battle{action}{$$trainer{ID}[0]}) {
            $$battle{action}{$$trainer{ID}[0]} = $action;
            if($$battle{type} < 2) {
              %result = (msg=>[],result=>1);
              if($$trainer{ID}[0] != 1) {
                $utility{'Pokemon_AITurn'}($utility{'Pokemon_getOpponent'}($trainer));
              }
            }
            else {
              %result = (msg=>["Waiting for other Trainer's action..."],result=>1);
            }
          }
          else {
            %result = (msg=>["You've already inputted your action."],result=>0);
          }
        }
        else {
          %result = (msg=>["The battle you were in seems to have disappeared. Resetting everything."],result=>0);
          $$trainer{mode} = 0;
          delete $$trainer{battleID};
        }
      }
      return \%result;
    },
    AITurn => sub {
      # I: Trainer
      # O: Null
      my $trainer = shift;
      my %action = (type=>0);
      if($$trainer{battleID}) {
        if($lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1]) {
          my $battle = $lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1];
          my $pkmn = $$trainer{party}[$$trainer{active}];
          $action{type} = 3;
          $action{arg} = int rand @{ $$pkmn{type} };
          $utility{'Pokemon_battleInput'}($trainer,\%action);
        }
      }
      return 1;
    },
    battleInfoText => sub {
      # I: Trainer
      # O: String
      my $trainer = shift;
      if(($$trainer{battleID}) && ($lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1])) {
        my $battle = $lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1];
        return $utility{'Pokemon_getInfo'}($$battle{trainers}[0]{party}[$$battle{trainers}[0]{active}],1)." ".$utility{'Pokemon_getInfo'}($$battle{trainers}[1]{party}[$$battle{trainers}[1]{active}],0)." ";
      }
      return $utility{'Pokemon_getInfo'}($$trainer{party}[($$trainer{active})?$$trainer{active}:0],1)." " if(@{ $$trainer{party} });
      return "";
    },
    battleGetTrainer => sub {
      # I: Battle, Trainer ID god why did I do this
      # O: Trainer
      my ($battle,$id) = (shift,shift);
      return ($$battle{trainers}[0]{ID}[0] == $id)?$$battle{trainers}[0]:$$battle{trainers}[1];
    },
    battleTurn => sub {
      # I: Trainer
      # O: Result Hash (msg, result)
      my $trainer = shift;
      #$utility{'Util_debugP'}($trainer);
      my %result = (msg => ["You're not in a battle"], result => 0);
      if($$trainer{battleID}) {
        if($lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1]) {
          my $battle = $lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1];
          @turns = keys %{ $$battle{action} };
          if(@turns == 2) {
            ## We're ready
            ## figure out turn order
            my $opponent = $utility{'Pokemon_getOpponent'}($trainer);
            my $sA = 999;
            $sA = $utility{'Pokemon_getStat'}($$trainer{party}[$$trainer{active}],5) if(@{ $$trainer{party} });
            my $sB = $utility{'Pokemon_getStat'}($$opponent{party}[$$opponent{active}],5);
            #print "Speed is $sA vs $sB\n";



            @turns = reverse(@turns) if($turns[0] != $$trainer{ID}[0]);
            @turns = reverse(@turns) if($sA < $sB);
            %result = (msg => [], result=>1);
            foreach $aID (0..3) {
              foreach $turn (@turns) {
                if($$battle{action}{$turn}{type} == $aID) {
                  my $wTrainer = $utility{'Pokemon_battleGetTrainer'}($battle,$turn);
                  #$utility{'Util_debugP'}($wTrainer);
                  my $arg = $$battle{action}{$turn}{arg};
                  if($aID == 0) {
                    # Run
                    if($$battle{type} != 0) { push(@{ $result{msg} }, "There's no running from a trainer battle."); next; }
                    foreach $tra (@{ $$battle{trainers} }) { $$tra{mode} = 0; delete $$tra{battleID}; }
                    push(@{ $result{msg} }, "You ran from the battle.");
                    return \%result;
                  }
                  elsif($aID == 1) {
                    # Item
                    # Arg item player index
                    my $items = $lk{tmp}{plugin}{'Pokemon'}{db}{items};
                    $$wTrainer{items}[ $arg ][1]--;
                    if($$items{$$wTrainer{items}[$arg][0]}{category_id} == 34) {
                      # Standard Pokeball
                      my %balls = ('1'=>255, '2'=>2, '3'=>1.5, '4'=>1, '456'=>1, '457'=>1, '5'=>1,'11'=>1,'12'=>1,'16'=>2);
                      my $opponent = $utility{'Pokemon_getOpponent'}($wTrainer);
                      my $oPokemon = $$opponent{party}[$$opponent{active}];
                      push(@{ $result{msg} }, "You threw a \x04".$$items{$$wTrainer{items}[ $arg ][0]}{name}."\x04!");
                      if($$battle{type} == 0) {
                        if($utility{'Pokemon_calculateCatch'}($oPokemon,$balls{ $$wTrainer{items}[ $arg ][0] }) >= rand) {
                          # We got a catch!
                          $$oPokemon{OT} = $$wTrainer{UBID};
                          $$oPokemon{caught_in} = $$wTrainer{items}[ $arg ][0];
                          $$oPokemon{caught_at} = time;
                          push(@{ $result{msg} }, ">>Gotcha! \x04".$utility{'Pokemon_getNick'}($oPokemon)."\x04 was caught!");
                          my %catch = %{ $utility{'Pokemon_awardPokemon'}($wTrainer,$oPokemon) };
                          push(@{ $result{msg} }, @{ $catch{msg} }) if(@{ $catch{msg} });
                          foreach $t ($wTrainer,$opponent) { $$t{mode} = 0; delete $$t{battleID}; }
                          delete $$battle{action};
                          return \%result;
                        }
                        else {
                          my @phrases = ("Oh no, \x04".$utility{'Pokemon_getNick'}($oPokemon)."\x04 broke free!", "Aww! It appeared to be caught!","Aargh! Almost had it!","Gah! It was so close, too!");
                          push(@{ $result{msg} }, $phrases[rand @phrases]);
                        }
                      }
                      else { push(@{ $result{msg} }, "You can't catch another trainer's pokemon!"); }
                      $utility{'Pokemon_fixItems'}($wTrainer);
                    }
                    else { $$wTrainer{items}[ $arg ][1]++; push(@{ $result{msg} }, "Item $$wTrainer{items}[ $arg ][0] hasn't been programmed yet bug Caaz!"); }
                  }
                  elsif($aID == 2) {
                    # Switch
                    # Arg party index
                    $$wTrainer{active} = $arg;
                    push(@{ $result{msg} }, "\x04".$utility{'Pokemon_getNick'}($$wTrainer{party}[$$wTrainer{active}])."\x04 was sent out.");
                  }
                  elsif($aID == 3) {
                    # Attack
                    my $wPokemon = $$wTrainer{party}[$$wTrainer{active}];
                    my $opponent = $utility{'Pokemon_getOpponent'}($wTrainer);
                    my $oPokemon = $$opponent{party}[$$opponent{active}];
                    #$utility{'Util_debugP'}($wPokemon);
                    if($$wPokemon{type}[ $arg ] <= 18) {
                      ## Normal attacks
                      my $types = $lk{tmp}{plugin}{'Pokemon'}{db}{types};
                      my $power = (@{ $$wPokemon{type} }==1)?90:50;
                      my %calc = %{$utility{'Pokemon_calculateDamage'}($wPokemon,$oPokemon,$$wPokemon{type}[ $arg ],$power)};
                      my $damage = $calc{damage};
                      $$oPokemon{damage} += $damage;
                      if($$oPokemon{ID} == 352) { $$oPokemon{ID}[0] = $$wPokemon{type}[ $arg ]; push(@{ $result{msg} }, "\x04".$utility{'Pokemon_getNick'}($oPokemon)."\x04's type changed!") }
                      push(@{ $result{msg} }, @{$calc{msg}});
                    }
                    else {
                      ## Alt Attacks
                      print "Got an alt attack!\n";
                    }
                    if($utility{'Pokemon_getStat'}($oPokemon,0) <= $$oPokemon{damage}) {
                      # This Pokemon has fainted
                      push(@{ $result{msg} }, "\x04".$utility{'Pokemon_getNick'}($oPokemon)."\x04 fainted.");

                      my $oldLevel = $utility{'Pokemon_getLevel'}($wPokemon);
                      my $exp = $utility{'Pokemon_calculateEXPGain'}($wTrainer,$wPokemon,$oPokemon,$$battle{type});
                      push(@{ $result{msg} }, "\x04".$utility{'Pokemon_getNick'}($wPokemon)."\x04 gained \x04$exp\x04 EXP!");
                      $$wPokemon{exp} += $exp * (($$wPokemon{held} == 208)?2:1);
                      $$wPokemon{happiness} += (($$wPokemon{held} == 195)?2:1) * int rand 15;
                      my $total = 0;
                      foreach $ev (@{ $$wPokemon{EV} }) { $total += $ev; }
                      if($total < 512) {
                        foreach $i (0..5) {
                          $$wPokemon{EV}[$i] += $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$oPokemon{ID}}{effort_reward}[$i];
                        }
                      }
                      my $newLevel = $utility{'Pokemon_getLevel'}($wPokemon);
                      if($oldLevel != $newLevel) {
                        push(@{ $result{msg} }, "\x04".$utility{'Pokemon_getNick'}($wPokemon)."\x04 leveled up!");
                        my %evo = %{ $utility{'Pokemon_checkEvolution'}($wTrainer,$wPokemon,0); };
                        push(@{ $result{msg} }, @{ $evo{msg} }) if(@{ $evo{msg} });
                      }

                      my %set = %{ $utility{'Pokemon_setActive'}($opponent) };
                      if($set{result} == 1) {
                        ## We can continue on.
                        $oPokemon = $$opponent{party}[$$opponent{active}];
                        push(@{ $result{msg} }, "\x04".$utility{'Pokemon_getNick'}($oPokemon)."\x04 was sent out!");
                      }
                      else {
                        ## award the winner! Using the loser's money!
                        #push(@{ $result{msg} }, "The battle is over.");
                        #push(@{ $result{msg} }, @{ $set{msg} });
                        my $award = int($$opponent{cash}*(.1 + rand .4));
                        if($award >= 10) {
                          $$opponent{cash} -= $award;
                          $$wTrainer{cash} += $award*(($$wPokemon{held} == 200)?2:1);
                          ## Insert award text here.
                          if($$battle{type} == 0) {
                            push(@{ $result{msg} }, "The winner gained \x04$award\x04P.");
                          }
                          else { push(@{ $result{msg} }, "The loser handed over \x04$award\x04P."); }
                        }


                        foreach $t ($wTrainer,$opponent) { $$t{mode} = 0; delete $$t{battleID}; }
                      }
                      delete $$battle{action};
                      return \%result;
                    }
                  }
                }
              }
            }
            delete $$battle{action};
          }
          else {
            %result = (msg=>["Waiting for other Trainer's action..."],0);
          }
        }
        else {
          %result = (msg=>["The battle you were in seems to have disappeared. ($lk{tmp}{plugin}{'Pokemon'}{battles}[$$trainer{battleID}-1]) ($trainer) ($$trainer{battleID} - 1) Resetting everything."],0);
          $$trainer{mode} = 0;
          delete $$trainer{battleID};
        }
      }
      return \%result;
    },
    calculateDamage => sub {
      #Input: Attacking Pokemon, Defending Pokemon, Attack Type
      #Return: Hash (damage, @{msg})
      my ($pkmnA,$pkmnD,$attack,$power) = (shift,shift,shift,shift);
      my @aStats = @{$utility{'Pokemon_getFullStats'}($pkmnA)};
      my @dStats = @{$utility{'Pokemon_getFullStats'}($pkmnD)};
      my $types = $lk{tmp}{plugin}{'Pokemon'}{db}{types};
      my $phys = ($$types{$attack}{damage_class_id}+1)*2-1;
      my $effectiveness = 1;
      my %result = (damage => 0, msg => []);
      foreach $def (@{ $$pkmnD{type} }) { $effectiveness *= $$types{$attack}{efficacy}{$def}/100; }
      my $crit = (rand() < 0.0625)?1.5:1;
      $result{damage} = int(((2*$utility{'Pokemon_getLevel'}($pkmnA)+10)/250*($aStats[$phys]/$dStats[$phys+1])*$power+2)*$effectiveness*$crit*(.85+(.15*rand)));
      push(@{$result{msg}}, "\x04".$utility{'Pokemon_getNick'}($pkmnA)."\x04 dealt \x04$result{damage}\x04 ".$$types{$attack}{name}." damage!");
      push(@{$result{msg}}, "\x04Critical hit\x04!") if($crit != 1);
      push(@{$result{msg}}, "It's ".(($effectiveness>1)?(($effectiveness==4)?"04F07A08B09U11L12O06U13S04L07Y08 09E11F12F06E13C04T07I08V09E\x04\x04.":"super-effective!"):(($effectiveness>0)?"not very effective.":"not effective!"))) if($effectiveness != 1);
      return \%result;
    },
    newTrainer => sub {
      #I: UBID
      #O: Result Hash?
      my $UBID = shift;
      %{$lk{data}{plugin}{'Pokemon'}{trainer}{$UBID}} = (
        active=>0,
        cash=>500,
        ID=>[10000 + int rand 89999,10000 + int rand 89999],
        UBID=>$UBID,
        mode=>0,
        items=>[],
        party=>[],
        PC=>[],
      );
      my $trainer = $lk{data}{plugin}{'Pokemon'}{trainer}{$UBID};
      my %result = (msg=>[],result=>1);
      push(@{$result{msg}},$utility{'Pokemon_awardItem'}($trainer,1,1));
      push(@{$result{msg}},"Use \x04item\x04 to see your inventory, and \x04item 1\x04 to use it while in battle.");
      return \%result;
    },
    calculateEXPGain => sub {
      # I : Trainer, Winning Pokemon, Losing Pokemon, Battle Type
      # O : EXP Gain
      my ($trainer,$wPkmn,$lPkmn,$type) = (shift,shift,shift,shift);
      my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn};
      my $lLevel = $utility{'Pokemon_getLevel'}($lPkmn);
      return int(((((($type == 0)?1:1.5)*$$db{$$lPkmn{ID}}{base_experience}*$lLevel)/5)*(2*$lLevel+10)**2.5/($lLevel+$utility{'Pokemon_getLevel'}($wPkmn)+10)**2.5+1)*(($$trainer{UBID} ~~  $$wPkmn{OT})?1:1.5));
    },
    calculateCatch => sub {
      # Input: Pokemon, BallRate
      my ($pokemon,$ball) = (shift,shift);
      my $mH = $utility{'Pokemon_getStat'}($pokemon,0);
      my $cH = $mH - $$pokemon{damage};
      #id,identifier,generation_id,evolves_from_species_id,evolution_chain_id,color_id,shape_id,habitat_id,gender_rate,capture_rate,
      my $cRate = $lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$$pokemon{ID}}{capture_rate};
      my $rate = ( 3 * $mH - 2 * $cH ) * ($cRate * $ball ) / (3 * $mH) / 255;
      # ((( 3 * $mH - 2 * $cH ) * ($cRate * $ball ) / (3 * $mH) ) * Status Modifier
      #print "Catch rate == $rate\ncH==$cH\nmH==$mH\nball==$ball\ncRate==$cRate";
      return $rate;
    },
    getFullAccount => sub {
      # I: Handle, Nickname
      # O: Hash (ub,id,trainer,result,msg);
      my $account = $utility{'Userbase_info'}($_[0],$_[1]);
      my $id = $utility{'Userbase_getID'}($_[0],$account);
      my %result = (result=>0,msg=>["Can't create a new trainer. No Userbase account."]);
      if($utility{'Userbase_isLoggedIn'}($_[0],$_[1])) {
        # Good account
        %result = (ub=>$account,id=>$id,result=>1,msg=>[]);
        if(!$lk{data}{plugin}{'Pokemon'}{trainer}{$id}) {
          my %newTrainer = %{ $utility{'Pokemon_newTrainer'}($id); };
          push(@{$result{msg}},@{$newTrainer{msg}});
        }
        $result{trainer} = $lk{data}{plugin}{'Pokemon'}{trainer}{$id};
      }
      return \%result;
    },
    check => sub {
      # I: Handle, Where, Trainer, Hash
      my @at = (shift,shift);
      my ($trainer,$check) = (shift,shift);
      if($$check{'array_length_min'}) { foreach $args (@{ $$check{'array_length_min'} }) { if(@{ $$args[0] }<$$args[1]) { $utility{'Fancify_say'}(@at,$$args[2]); return 0; } } }
      if($$check{'array_length_max'}) { foreach $args (@{ $$check{'array_length_max'} }) { if(@{ $$args[0] }>$$args[1]) { $utility{'Fancify_say'}(@at,$$args[2]); return 0; } } }
      if($$check{'mode_not'}) { if ($$trainer{mode} ~~ @{ $$check{mode_not}[0] }) { $utility{'Fancify_say'}(@at,$$check{mode_not}[1]); return 0; } }
      if($$check{'mode'}) { if(!($$trainer{mode} ~~ @{ $$check{mode}[0] })) { $utility{'Fancify_say'}(@at,$$check{mode}[1]); return 0; } }
      $$trainer{'commands'}++;
      return 1;
    },
  },
  code => { load => sub { $lk{plugin}{'Pokemon'}{utilities}{loadDB}(); } },
  commandsV2 => {
    'Summary(?<key> pc)? (?<id>\d+)' => {
      access=>0,
      cooldown => 2,
      description => "Views detailed information on Pokemon.",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my $key = ($+{key})?'PC':'party';
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{$key},1,"You don't have any Pokemon in your $key yet!"], [$acc{trainer}{$key},$selection+1,"No Pokemon in that slot."] ]
        })) {
          $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_getInfo'}($acc{trainer}{$key}[$selection],5));
        }
      }
    },
    '(?<key>(?:PC|Party)) Sort (?<type>\w+)' => {
      access => 0,
      cooldown => 2,
      description => "Sorts PC Pokemon.",
      code => sub {
        my $key = $+{key};
        my $type = $+{type};
        $key = ($key=~/^PC/i)?'PC':'party';
        $type = ($type =~ /dex/i)?1:($type=~/name/i)?2:($type=~/level/i)?3:0;
        print "My Type = $type\n";
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{ 'array_length_min' => [ [$acc{trainer}{$key},1,"You don't have any Pokemon in your $key yet!"] ] })) {

          @{ $acc{trainer}{$key} } = sort { $$a{ID} <=> $$b{ID} } @{ $acc{trainer}{$key} } if($type == 1);
          @{ $acc{trainer}{$key} } = sort { $utility{'Pokemon_getNick'}($a) cmp $utility{'Pokemon_getNick'}($b) } @{ $acc{trainer}{$key} } if($type == 2);
          @{ $acc{trainer}{$key} } = sort { $utility{'Pokemon_getLevel'}($a) <=> $utility{'Pokemon_getLevel'}($b) } @{ $acc{trainer}{$key} } if($type == 3);
          my %result = %{$utility{'Pokemon_setActive'}($acc{trainer})};
          $utility{'Fancify_say'}($_[1],$_[2],($type)?"Your $key is sorted!":"Invalid sort!");
        }
      }
    },
    'PC(?: (?<page>\d+))?' => {
      access=>0,
      cooldown => 2,
      description => "Views PC Pokemon.",
      code => sub {
        my $page = ($+{page})?$+{page}:1;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{ 'array_length_min' => [ [$acc{trainer}{PC},1,"You don't have any Pokemon in your PC yet!"] ] })) {
          my $start = ($page-1)*8; my @pk = ();
          foreach(($start)..($start+8-1)) { push(@pk,'['.$utility{'Pokemon_getInfo'}($acc{trainer}{PC}[$_],6,($_+1)).']') if($acc{trainer}{PC}[$_]); }
          if(@pk) { $utility{'Fancify_say'}($_[1],$_[2],"[Page \x04$page\x04/\x04".int((@{$acc{trainer}{PC}}-1)/8+1)."\x04] ".join " ",@pk); }
          else {  $utility{'Fancify_say'}($_[1],$_[2],"No Pokemon on that page."); }
        }
      }
    },
    'Deposit (?<id>\d+)' => {
      access=>0,
      description => "Deposits a pokemon into the PC",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{party},$selection+1,"No Pokemon in that slot"] ],
          'mode' => [[0],"You can't do that right now"]
        })) {
          if(@{ $acc{trainer}{party} } == 1) { $utility{'Fancify_say'}($_[1],$_[2],"You can't deposit your only pokemon!"); return 0; }
          $utility{'Fancify_say'}($_[1],$_[2],${ $utility{'Pokemon_depositPC'}($acc{trainer},$selection) }{msg});
        }
      }
    },
    'Withdraw (?<id>\d+)' => {
      access=>0,
      description => "Deposits a pokemon into the PC",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{PC},$selection+1,"No Pokemon in that slot."] ],
          'array_length_max' => [ [$acc{trainer}{party},5,"Your party is full! Deposit some first."] ],
          'mode' => [[0],"You can't do that right now"]
        })) {
          push(@{ $acc{trainer}{party} },splice(@{ $acc{trainer}{PC} },$selection,1));
          $utility{'Fancify_say'}($_[1],$_[2],"Withdrew ".$utility{'Pokemon_getInfo'}($acc{trainer}{party}[-1],6)." from the PC.");
        }
      }
    },
    'Trade(?<key> pc)? (?<id>\d+) (?<ub>\d+)' => {
      access=>0,
      cooldown => 2,
      description => "Releases a Pokemon",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my $key = ($+{key})?'PC':'party';
        my $ub = $+{ub}+0;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [
            [$acc{trainer}{$key},1,"You don't have any Pokemon in your $key yet!"], [$acc{trainer}{$key},$selection+1,"No Pokemon in that slot."],
          ],
          'mode' => [[0],"You can't do that right now"],
        })) {
          unless($lk{data}{plugin}{'Pokemon'}{trainer}{$ub}) { $utility{'Fancify_say'}($_[1],$_[2],"No trainer with that Userbase ID"); return 0; }
          if($ub == $acc{trainer}{UBID}+0) { $utility{'Fancify_say'}($_[1],$_[2],"You can't trade yourself!"); return 0; }
          my $friend = $lk{data}{plugin}{'Pokemon'}{trainer}{$ub};
          if(length $acc{trainer}{offer}[0]) { $utility{'Fancify_say'}($_[1],$_[3],"You can't change your offer. Use \x04Trade Cancel\x04 instead."); }
          else {
            #if($$friend{mode} != 0) { $utility{'Fancify_say'}($_[1],$_[2],"They can't trade right now..."); return 0; }
            $acc{trainer}{mode} = 2;
            @{ $acc{trainer}{offer} }  = ($key,$selection,$ub);
            if(($$friend{mode} == 2) && (@{ $$friend{offer} }) && ($$friend{offer}[2] == $acc{trainer}{UBID})) {
              $utility{'Fancify_say'}($_[1],$$friend{currently},"\x04$acc{trainer}{name}\x04 offered their ".$utility{'Pokemon_getInfo'}($acc{trainer}{$key}[ $selection ],6)." for your ".$utility{'Pokemon_getInfo'}($$friend{$$friend{offer}[0]}[ $$friend{offer}[1] ],6).". Accept offer with \x04Trade Accept\x04, otherwise \x04Trade Cancel\x04");
            }
            else {
              $utility{'Fancify_say'}($_[1],$$friend{currently},"\x04$acc{trainer}{name}\x04 offered their ".$utility{'Pokemon_getInfo'}($acc{trainer}{$key}[ $selection ],6)." to trade! Offer something back with \x04Trade (PC)? <Selection> $acc{trainer}{UBID}\x04");
            }
            $utility{'Fancify_say'}($_[1],$_[3],"You offerred \x04$$friend{name}\x04 your ".$utility{'Pokemon_getInfo'}($acc{trainer}{$key}[ $selection ],6).". Waiting for their response... Cancel with \x04Trade Cancel\x04");
          };
        }
      }
    },
    'Trade (?<choice>cancel|accept)' => {
      access=>0,
      cooldown => 2,
      description => "Releases a Pokemon",
      code => sub {
        my $choice = ($+{choice} =~ /^c/)?1:0;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{ 'mode' => [[2],"You can't do that right now."], })) {
          my $friend = $lk{data}{plugin}{'Pokemon'}{trainer}{$acc{trainer}{offer}[2]};
          if($choice) {
            # Cancel
            $utility{'Fancify_say'}($_[1],$_[3],"You cancelled the trade.");
            $utility{'Fancify_say'}($_[1],$$friend{currently},"\x04$acc{trainer}{name}\x04 canceled the trade.");
            if(($$friend{mode} == 2) && (@{ $$friend{offer} }) && ($$friend{offer}[2] == $acc{trainer}{UBID})) { delete $$friend{offer}; $$friend{mode} = 0; }
          }
          else {
            if(($$friend{mode} == 2) && (@{ $$friend{offer} }) && ($$friend{offer}[2] == $acc{trainer}{UBID})) {
              ## Trade!
              my $sPkmn = splice(@{ $acc{trainer}{$acc{trainer}{offer}[0]} },$acc{trainer}{offer}[1],1);
              my $rPkmn = splice(@{ $$friend{ $$friend{offer}[0] } },$$friend{offer}[1],1);
              foreach $trade ([$friend,$sPkmn],[$acc{trainer},$rPkmn]) {
                my %catch = %{ $utility{'Pokemon_awardPokemon'}($$trade[0],$$trade[1]) };
                my %evo = %{ $utility{'Pokemon_checkEvolution'}($$trade[0],$$trade[1],1) };
                $utility{'Fancify_say'}($_[1],$$trade[0]{currently},"You received ".$utility{'Pokemon_getInfo'}($$trade[1],6)."!".((@{$catch{msg}})?" ".(join " ",@{ $catch{msg} }):'').((@{$evo{msg}})?" ".(join " ", @{ $evo{msg} }):''));
                delete $$trade[0]{offer}; $$trade[0]{mode} = 0;
              }
            }
            else {
              $utility{'Fancify_say'}($_[1],$_[3],"It looks like the trade failed?");
            }
          }
          $acc{trainer}{mode} = 0; delete $acc{trainer}{offer};
        }
      }
    },
    '(?:Wondertrade|WT)(?<key> pc)?(?: (?<id>\d+))?' => {
      access=>0,
      cooldown => 2,
      description => "Views detailed information on Pokemon.",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:0;
        my $key = ($+{key})?'PC':'party';
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{$key},1,"You don't have any Pokemon in your $key yet!"], [$acc{trainer}{$key},$selection+1,"No Pokemon in that slot."], ],
          'mode' => [[0],"You can't do that right now"],
        })) {
          @{$lk{data}{plugin}{'Pokemon'}{wondertrade}} = () if(!$lk{data}{plugin}{'Pokemon'}{wondertrade});
          my $wonderful = $lk{data}{plugin}{'Pokemon'}{wondertrade};
          unless(@{ $wonderful }) { $utility{'Fancify_say'}($_[1],$_[2],"There's no pokemon available right now..."); return 0;  }
          if($+{id}) {
            my $newPkmn = splice(@{ $wonderful },int rand @{ $wonderful },1);
            my $oldPkmn = splice(@{ $acc{trainer}{$key} },$selection,1);
            push(@{ $wonderful },$oldPkmn);
            my %catch = %{ $utility{'Pokemon_awardPokemon'}($acc{trainer},$newPkmn) };
            my %evo = %{ $utility{'Pokemon_checkEvolution'}($acc{trainer},$newPkmn,1) };
            $utility{'Fancify_say'}($_[1],$_[2],"You gave up \x04".$utility{'Pokemon_getNick'}($oldPkmn)."\x04 and... You received ".$utility{'Pokemon_getInfo'}($newPkmn,6)." from ".${$utility{'Pokemon_findOT'}($$newPkmn{OT})}{name}."!".((@{$catch{msg}})?" ".(join " ",@{ $catch{msg} }):'').((@{$evo{msg}})?" ".(join " ", @{ $evo{msg} }):''));
          }
          else {
            $utility{'Fancify_say'}($_[1],$_[2],"There are \x04".(@{ $wonderful}+0)."\x04 Pokemon in wondertrade right now.");
          }
        }
      }
    },
    'Release(?<key> pc)?(?: (?<id>\d+))' => {
      access=>0,
      cooldown => 2,
      description => "Views detailed information on Pokemon.",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my $key = ($+{key})?'PC':'party';
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [
            [$acc{trainer}{$key},1,"You don't have any Pokemon in your $key yet!"],
            [$acc{trainer}{$key},$selection+1,"No Pokemon in that slot."],
            [$acc{trainer}{$key},($key=~/pc/)?0:1,"You can't release your only pokemon!"],
          ],
          'mode' => [[0],"You can't do that right now"],
        })) {
          @{$lk{data}{plugin}{'Pokemon'}{wondertrade}} = () if(!$lk{data}{plugin}{'Pokemon'}{wondertrade});
          my $wonderful = $lk{data}{plugin}{'Pokemon'}{wondertrade};
          my $oldPkmn = splice(@{ $acc{trainer}{$key} },$selection,1);
          push(@{ $wonderful },$oldPkmn);
          $utility{'Fancify_say'}($_[1],$_[2],"You released ".$utility{'Pokemon_getInfo'}($oldPkmn,6));
        }
      }
    },
    'Nick(?:name)?(?<key> pc)?(?: (?<id>\d+)) (?<nick>[\w\s]+)' => {
      access=>0,
      cooldown => 2,
      description => "Changes Pokemon Nickname.",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my $key = ($+{key})?'PC':'party';
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{$key},1,"You don't have any Pokemon in your $key yet!"],
						[$acc{trainer}{$key},$selection,"Something something fuck you $key!"] ],
          'array_length_max' => [ [[split //, $+{nick}],15,"That's too long of a nickname."] ],
        })) {
          unless((length $acc{trainer}{$key}[$selection]{nickname} < 1) || ($acc{trainer}{UBID} ~~ $acc{trainer}{$key}[$selection]{OT})) { $utility{'Fancify_say'}($_[1],$_[2],"You can't nickname this pokemon!"); return 0; }
          $utility{'Fancify_say'}($_[1],$_[2],"You renamed your \x04".$lk{tmp}{plugin}{'Pokemon'}{db}{pkmn}{$acc{trainer}{$key}[$selection]{ID}}{name}."\x04 to \x04$+{nick}\x04!");
          $acc{trainer}{$key}[$selection]{nickname} = $+{nick};
        }
      }
    },
    'Party' => {
      access=>0,
      cooldown => 2,
      description => "Checks Pokemon Party.",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{party},1,"You don't have any Pokemon in your party yet!"] ],
        })) {
          my @party = ();
          foreach $pkmn (@{ $acc{trainer}{party} }) { push(@party,$utility{'Pokemon_getInfo'}($pkmn,3,($acc{trainer}{active}==@party)?"\x04!\x04":($acc{trainer}{mode}!=0)?(@party+1):'')); }
          $utility{'Pokemon_fixTrainer'}(\%acc);
          @modes = ('',' In Battle',' Trading');
          $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_trainerInfo'}($acc{trainer},0).' '.(join " ", @party));
        }
      }
    },
    'pkmnexport' => {
      access=>0,
      cooldown => 2,
      description => "Exports trainer data.",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{party},1,"You don't have any Pokemon in your party yet!"] ],
        })) {
          $utility{'Pokemon_fixTrainer'}(\%acc);
          $utility{'Pokemon_exportTrainer'}($acc{trainer});
          $utility{'Fancify_say'}($_[1],$_[2],"Trainer information exported! Check it out at https://dl.dropboxusercontent.com/u/9305622/Dev/pkmn/view.html?id=".$acc{id});
        }
      }
    },
    '(?:(?:Poke)?Center|heal)' => {
      access=>0,
      cooldown => 2,
      description => "Forces a wild pokemon to appear.",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{party},1,"You don't have any Pokemon in your party yet!"] ],
          'mode_not' => [[1],"You can't go to the pokecenter right now!"],
        })) {
          $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_healAllPokemon'}($acc{trainer}));
        }
      }
    },
    'Wild' => {
      access=>0,
      cooldown => 1,
      description => "Heals your pokemon.",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{'mode' => [[0],"You can't use that right now!"]})) {
          my %result = %{$utility{'Pokemon_newBattle'}($acc{trainer},0,[$utility{'Pokemon_getPokemon'}((@{$acc{trainer}{party}}>=1)?$utility{'Pokemon_getLevel'}($acc{trainer}{party}[$acc{trainer}{active}])-5:2)])};
          $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$result{msg}});
        }
      }
    },
    'TrainerBattle' => {
      access=>0,
      cooldown => 1,
      description => "Starts a battle with an AI Trainer.",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{party},1,"You don't have any Pokemon in your party yet!"] ], 'mode' => [[0],"You can't use that right now!"],
        })) {
          my @tpkmn; foreach(0..(1+int rand 5)) { push(@tpkmn,$utility{'Pokemon_getPokemon'}((@{$acc{trainer}{party}}>=1)?$utility{'Pokemon_getLevel'}($acc{trainer}{party}[$acc{trainer}{active}])-5:2)); }
          my %result = %{$utility{'Pokemon_newBattle'}($acc{trainer},1,\@tpkmn)}; if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$result{msg}}); }
        }
      }
    },
    'Attack ?(?<id>\d+)?' => {
      access=>0,
      description => "Attacks.",
      code => sub {
        my $selection = $+{id}-1 if($+{id});
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'mode' => [[1],"You can't use that right now!"],
          'array_length_min' => [ [$acc{trainer}{party}[$acc{trainer}{active}]{type},$selection+1,"Not a valid selection."], ]
        })) {
          if($+{id}) {
            my %result = %{$utility{'Pokemon_battleInput'}($acc{trainer},{type=>3,arg=>$selection})};
            if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[3],join " ", @{$result{msg}}); }
            %result = %{$utility{'Pokemon_battleTurn'}($acc{trainer})};
            if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[3],$utility{'Pokemon_battleInfoText'}($acc{trainer}).(join " ", @{$result{msg}})); }
          }
          else {
            my $db = $lk{tmp}{plugin}{'Pokemon'}{db};
            my $pkmn = $acc{trainer}{party}[$acc{trainer}{active}];
            my @types = (); my $i = 1;
            foreach(@{ $$pkmn{type} }) { push(@types, "[$i: ".$$db{types}{$_}{name}."]"); $i++; }
            $utility{'Fancify_say'}($_[1],$_[2],join " ", @types);
          }
        }
      }
    },
    'Item ?(?<id>\d+)?' => {
      access=>0,
      description => "Uses an item.",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:-1;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{items},$selection+1,"Not a valid selection."] ]
        })) {
          $utility{'Pokemon_fixItems'}($acc{trainer});
          if($+{id}) {
            if($acc{trainer}{mode} != 1) { $utility{'Fancify_say'}($_[1],$_[2],"You can't do this right now."); return 0; }
            my %result = %{$utility{'Pokemon_battleInput'}($acc{trainer},{type=>1,arg=>$selection})};
            if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[3],join " ", @{$result{msg}}); }
            %result = %{$utility{'Pokemon_battleTurn'}($acc{trainer})};
            if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[3],$utility{'Pokemon_battleInfoText'}($acc{trainer}).(join " ", @{$result{msg}})); }
          }
          else {
            my @list = (); my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{items}; my $i = 1;
            foreach $it (@{ $acc{trainer}{items} }) { push(@list, "[$i: \x04".$$db{$$it[0]}{name}."\x04x\x04".$$it[1]."\x04]") unless($$it[1]<1); $i++; }
            if(@list > 10) { $utility{'Fancify_say'}($_[1],$_[2],"You have too many items, instead use the non-existant search feature."); }
            else { $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_trainerInfo'}($acc{trainer},0).' '.(join " ", @list)); }
          }
        }
      }
    },
    'Give(?<key> pc)?(?: (?<id>\d+)) (?<item>\d+)' => {
      access=>0,
      description => "Gives a Pokemon an item to hold",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my $key = ($+{key})?'PC':'party';
        my $item = ($+{item})?$+{item}-1:0;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{$key},$selection+1,"No Pokemon in that slot"], [$acc{trainer}{items},$item+1,"No item in that slot."] ],
          'mode' => [[0],"You can't do that right now"]
        })) {
          my $msg = $utility{'Pokemon_awardItem'}($acc{trainer},$acc{trainer}{$key}[ $selection ]{held},1) if($acc{trainer}{$key}[$selection]{held});
          $acc{trainer}{$key}[$selection]{held} = $acc{trainer}{items}[$item][0]; $acc{trainer}{items}[$item][1]--;
          my $name = $lk{tmp}{plugin}{'Pokemon'}{db}{items}{$acc{trainer}{items}[$item][0]}{name};
          my %evo = %{ $utility{'Pokemon_checkEvolution'}($acc{trainer},$acc{trainer}{$key}[$selection],0) };
          $utility{'Fancify_say'}($_[1],$_[2],"You gave \x04".$utility{'Pokemon_getNick'}($acc{trainer}{$key}[$selection])."\x04 a".(($name =~ /^[aeiou]/i)?'n':'')." \x04$name\x04 to hold.".(($msg)?" $msg":'').((@{$evo{msg}})?" ".(join " ", @{ $evo{msg} }):''));
          $utility{'Pokemon_fixItems'}($acc{trainer});
        }
      }
    },
    'Take(?<key> pc)?(?: (?<id>\d+))' => {
      access=>0,
      description => "Gives a Pokemon an item to hold",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:1;
        my $key = ($+{key})?'PC':'party';
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{$key},$selection+1,"No Pokemon in that slot"] ],
          'mode' => [[0],"You can't do that right now"]
        })) {
          if($acc{trainer}{$key}[$selection]{held}) {
            my $msg = $utility{'Pokemon_awardItem'}($acc{trainer},$acc{trainer}{$key}[ $selection ]{held},1);
            $acc{trainer}{$key}[ $selection ]{held} = 0;
            $utility{'Fancify_say'}($_[1],$_[2],$msg);
          }
          else {
            $utility{'Fancify_say'}($_[1],$_[2],"\x04".$utility{'Pokemon_getNick'}($acc{trainer}{$key}[$selection])."\x04 isn't holding an item.");
          }
        }
      }
    },
    'Switch (?<id>\d+)' => {
      access=>0,
      description => "Switches pokemon",
      code => sub {
        my $selection = ($+{id})?$+{id}-1:0;
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{
          'array_length_min' => [ [$acc{trainer}{party},$selection+1,"No Pokemon in that slot"] ]
        })) {
          my $pkmn = $acc{trainer}{party}[$selection];
          if($$pkmn{damage} >= $utility{'Pokemon_getStat'}($pkmn,0)) {  $utility{'Fancify_say'}($_[1],$_[2],"That Pokemon has fainted!"); return 0; }
          if($acc{trainer}{mode} == 0) {
            # Idle
            my %tmpPokemon = %{$acc{trainer}{party}[0]};
            %{$acc{trainer}{party}[0]} = %{ $acc{trainer}{party}[$selection] };
            %{ $acc{trainer}{party}[$selection] } = %tmpPokemon;
            my %result = %{$utility{'Pokemon_setActive'}($acc{trainer})};
            $utility{'Fancify_say'}($_[1],$_[2],$result{msg});
          }
          elsif($acc{trainer}{mode} == 1) {
            # Battle
            my %result = %{$utility{'Pokemon_battleInput'}($acc{trainer},{type=>2,arg=>$selection})};
            if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$result{msg}}); }
            %result = %{$utility{'Pokemon_battleTurn'}($acc{trainer})};
            if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_battleInfoText'}($acc{trainer}).' '.(join " ", @{$result{msg}})); }
          }
          else {
            $utility{'Fancify_say'}($_[1],$_[2],"You can't do that now.");
          }
        }
      }
    },
    'Run' => {
      access=>0,
      description => "Runs away from the battle.",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($utility{'Pokemon_check'}($_[1],$_[2],$acc{trainer},{'mode' => [[1],"Run from what exactly?"]})) {
          my %result = %{$utility{'Pokemon_battleInput'}($acc{trainer},{type=>0,arg=>0})};
          if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$result{msg}}); }
          %result = %{$utility{'Pokemon_battleTurn'}($acc{trainer})};
          if(@{$result{msg}}) { $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_battleInfoText'}($acc{trainer}).(join " ", @{$result{msg}})); }
        }
      }
    },

    ## Eh

    'Mart ?(?<search>[\w\s]+)' => {
      cooldown => 4,
      description => "Searches for items in the Pokemart",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($acc{trainer}{mode} != 0) { $utility{'Fancify_say'}($_[1],$_[2],"You can't do that right now."); return 0; }
        my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{items};
        my @items = ();
        my @msg = ();
        foreach(@{ $utility{'Util_find'}($db,'name',$+{search}) }) {
          push(@items,$_) if($$db{$_}{cost});
        }
        foreach(@items) { push(@msg,"[$_ \x04$$db{$_}{name} $$db{$_}{cost}\x04] ");  }
        if(@msg > 20) { $utility{'Fancify_say'}($_[1],$_[2],"Too many items found. (".(@items+0).") Try a better search."); return 0; }
        else {
          $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_trainerInfo'}($acc{trainer},0).' '.(join "", @msg));
        }
      }
    },
    'Buy (?<id>\d+)(?: (?<amount>\d+))?' => {
      description => "Buys any item by ID",
      code => sub {
        my %acc = %{$utility{'Pokemon_getFullAccount'}($_[6],$_[3])}; $utility{'Fancify_say'}($_[1],$_[2],join " ", @{$acc{msg}}) if(@{$acc{msg}}); return 0 unless($acc{result});
        if($acc{trainer}{mode} != 0) { $utility{'Fancify_say'}($_[1],$_[2],"You can't do that right now."); return 0; }
        my $db = $lk{tmp}{plugin}{'Pokemon'}{db}{items};
        if((!$$db{$+{id}}) || ($$db{$+{id}}{cost}<1)) { $utility{'Fancify_say'}($_[1],$_[2],"No such item by that ID"); return 0; }
        my $amount = 1;
        $amount += $+{amount}-1 if($+{amount});
        $amount = 50 if($amount>50);
        my $price = $$db{$+{id}}{cost}*$amount;
        if($acc{trainer}{cash} < $price) { $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_trainerInfo'}($acc{trainer},0)." You don't have enough cash for that. (\x04$price\x04)"); return 0; }
        $acc{trainer}{cash} -= $price;
        $utility{'Fancify_say'}($_[1],$_[2],$utility{'Pokemon_trainerInfo'}($acc{trainer},0).' '.$utility{'Pokemon_awardItem'}($acc{trainer},$+{id},$amount));
        $utility{'Pokemon_fixItems'}($acc{trainer});
      }
    },
  },
});
