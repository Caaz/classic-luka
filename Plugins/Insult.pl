addPlug('Insult', {
  'creator' => 'Caaz',
  'version' => '1',
  'description' => "Tumblr-Style insults and rants",
  'name' => 'Tumblr Insult generator',
  'dependencies' => ['Caaz_Utilities'],
  'utilities' => {
    'parse' => sub {
      my $text = $_[0];
      my %resources = %{$lk{plugin}{'Insult'}{resources}};
      my $parsing = 1;
      while ($parsing) {
        $parsing = 0;
        while($text =~ /(?:\[(.+?)\])/) {
          $parsing = 1;
          my $pick = $1;
          my @options = split /\|/, $pick;
          $pick =~ s/(\W)/\\$1/g;
          $text =~ s/\[$pick\]/$options[rand @options]/;
        }
        while($text =~ /(?:\{((?:.+?\|)+.+?)\})/) {
          $parsing = 1;
          my $pick = $1;
          my @options = split /\|/, $pick;
          $pick =~ s/(\W)/\\$1/g;
          $text =~ s/\{$pick\}/\{$options[rand @options]\}/;
        }
        while($text =~ /(?:\{(.+?)\})/) {
          $parsing = 1;
          my $loc = $1;
          my $mod;
          if($loc =~ /\#(.+)$/) { $mod = $1; }
          my $actual = $loc;
          $actual =~ s/\#.+$//g;
          my @args = split /\./, $actual;
          my $structure = '{'.(join '}{', @args).'}';
          my $result = eval('$resources'.$structure);
          if($@) { lkDebug(">>>>$text"); lkDebug(">>$structure"); return '[Error]'; }
          if($result =~ /^ARRAY/) {
            my $chosen = ${$result}[rand @{$result}];
            if($chosen =~ /^ARRAY/) { $chosen = ${$chosen}[rand @{$chosen}]; }
            if($mod) {
              if($mod =~ /pluralize/) { $chosen = &{$utility{'Core_Utilities_pluralize'}}($chosen, 2); }
            }
            $text =~ s/\{$loc\}/$chosen/;
          }
          else { $text =~ s/\{$loc\}/\($loc HAD ERRARS\)/; last; }
        }
      }
      $text =~ s/^([\w']+)/\u\L$1/g;
      return $text;
    },
    'tumblr' => sub {
      # Input: Type,
      # 0 => You/Nick
      # 1 => Rant
      # Output: Text returned
      if((!$_[0]) or ($_[0] == 0)) {
        $name = ($_[2])?$_[2].'.':'you';
        $string = ($_[1])?"{insults.statements}, $name ":"";
        $string .= '{insults.adjectives} ' if(rand > .3);
        $string = (rand > .3)?$string.'{marginalized.nouns|marginalized.adjectives}-{marginalized.verbs} ':$string."you ";
        $string .= '{privileged.nouns}-{privileged.adjectives} {insults.nouns}!';
        return $utility{'Insult_parse'}($string);
      }
      elsif($_[0] == 1) {
        my $count = int(rand(2)+1);
        my $string;
        $string .= $utility{'Insult_parse'}('{presentations}. ') if(rand > .5);
        foreach(0..$count) {
          if($_ > 0) {
            if(rand > .8) { $string .= $utility{'Insult_tumblr'}(0,($_ == 0)? 1:0).'. '; }
            else { $string .= $utility{'Insult_parse'}('{statementToldYouTo} {insults.statements}. '); }
          }
          else { $string .= $utility{'Insult_parse'}('{statements} '); }
        }
        return $utility{'Insult_parse'}("{intros} ").$string.$utility{'Insult_parse'}("{conclusions}");
      }
    },
  },
  'resources' => {
    alignments => [
      ['androamorous','androromantic','androplatonic','androsensual','androsexual','andro','anthroamorous','anthroromantic','anthroplatonic','anthrosensual','anthrosexual','anthro','demiamorous','demiromantic','demiplatonic','demisensual','demisexual','demi','genderamorous','genderromantic','genderplatonic','gendersensual','gendersexual','gender','grayamorous','grayromantic','grayplatonic','graysensual','graysexual','gray','gyneamorous','gyneromantic','gyneplatonic','gynesensual','gynesexual','gyne','pomoamorous','pomoromantic','pomoplatonic','pomosensual','pomosexual','pomo','skolioamorous','skolioromantic','skolioplatonic','skoliosensual','skoliosexual','skolio','tulpaamorous','tulparomantic','tulpaplatonic','tulpasensual','tulpasexual','tulpa'],
      ['aethnic','agender','aqueer','aracial','aromantic','asensual','asexual','aspecies','apost','biethnic','bigender','biqueer','biracial','biromantic','bisensual','bisexual','bispecies','bipost','demiethnic','demigender','demiqueer','demiracial','demiromantic','demisensual','demisexual','demispecies','demipost','interethnic','intergender','interqueer','interracial','interromantic','intersensual','intersexual','interspecies','interpost','multiethnic','multigender','multiqueer','multiracial','multiromantic','multisensual','multisexual','multispecies','multipost','nonethnic','nongender','nonqueer','nonracial','nonromantic','nonsensual','nonsexual','nonspecies','nonpost','omniethnic','omnigender','omniqueer','omniracial','omniromantic','omnisensual','omnisexual','omnispecies','omnipost','panethnic','pangender','panqueer','panracial','panromantic','pansensual','pansexual','panspecies','panpost','paraethnic','paragender','paraqueer','pararacial','pararomantic','parasensual','parasexual','paraspecies','parapost','polyethnic','polygender','polyqueer','polyracial','polyromantic','polysensual','polysexual','polyspecies','polypost','transethnic','transgender','transqueer','transracial','transromantic','transsensual','transsexual','transspecies','transpost']
    ],
    privileged => {
      nouns => ["able-body", "binary", "cis", "cisgender", "cishet", "gender", "hetero", "male", "middle class", "non-ethnic", "smallfat", "thin", "uterus-bearer", "white", "white womyn"],
      adjectives => ["normative", "elitist", "overprivileged", "privileged"],
    },
    phobias => [
      ["bi", "curvy", "deathfat", "ethno", "fat", "femme", "furry", "hetero", "homo", "lesbo", "male", "otherkin", "phallo", "poly", "queer", "trans*", "womyn"],
      ["phobic",""]
    ],
    supremacies => [
      # Privileged nouns...
      ["culture", "domination", "entitlement", "feminism", "kyriarchy", "opinions", "privilege", "rights", "superiority", "supremacy"]
    ],
    institutions => [
      ["institutionalized", "internalized"],
      ["gender roles", "masculinity", "misogynism", "patriarchy", "racism"]
    ],
    concepts => {
      awesome => [
        ["[self-diagnosed] [racial|gender|species] dysphoria", "bodily integrity", "body hair", "communism", "diversity", "egalitarianism", "fandomism", "fat love", "fatism", "female rights", "female superiority", "female supremacy", "femininity", "feminism", "food addiction", "freeganism", "gender abolition", "gender neutrality", "gender-neutral pronouns", "intersectionality", "invisible people", "lesbianism", "misandry", "multiple systems", "non-white culture", "obesity", "other ethnicities", "people of color", "prosthetic-wearers", "social justice", "socialism", "stretchmarks", "veganism", "vegetarianism"],
        ["", "anti-porn", "body-positivity", "environmental", "fat rights", "gay rights", "gay", "lesbian", "social justice", "trans*", "animal rights"],
        ["activism", "separatism"]
      ],
      terrible => [
        ["TERFism", "bindi wearing", "colonization", "cultural appropriation", "exotification", "female self esteem erosion", "gender equality", "gender roles", "hypermasculinity", "labeling", "masculinity", "men's rights", "patriarchal beauty standards", "rape culture", "sexuality labels"]
        # discriminations, supremacies, institutions...
      ],
    },
    conclusions => [
      ["[in conclusion|tl;dr]: {insults.statements}!", "[shut up and] never reblog my posts ever again.", "feel free to unfollow and/or block/ignore me.", "fucking {privileged.nouns}-{privileged.adjectives} people.", "i can't even.", "i'm [literally] 100% done.", "now go [the fuck] away.", "please leave me alone.", "try again, {insults.nouns}.", "unfollow me right now.", "you cannot fight {concepts.terrible} using {concepts.terrible}.", "you guys are [fucking] impossible."],
    ],
    emoji => ["(◕﹏◕✿)", "（　｀ー´）", "(•﹏•)", "└(｀0´)┘", "ᕙ(⇀‸↼‶)ᕗ", "ᕦ(ò_óˇ)ᕤ", "(⋋▂⋌)", "(¬_¬)", "٩(×̯×)۶", "(╯°□°)╯︵ ┻━┻", "(⊙﹏⊙✿)", "(ﾉ◕ヮ◕)ﾉ*: ･ﾟ✧", "(⊙_◎)"],
    insults => {
      statements => ["[acknowledge|check] your [fucking] {privileged.nouns} privilege", "burn in hell", "choke on a bag of dicks", "die in a [ditch|fire]", "drink bleach", "drop dead", "fuck [off|you]", "get bent", "get fucked with a cactus", "go drown in your own piss", "go fuck yourself", "go play in traffic", "go to hell", "kill yourself", "light yourself on fire", "make love to yourself in a furnace", "rot in hell", "screw you", "shut [the fuck] up"],
      adjectives => ["antediluvian", "awful", "body-shaming", "chauvinistic", "ciscentric", "close-minded", "deluded", "entitled", "fedora-wearing", "fucking", "goddamn", "heteropatriarchal", "ignorant", "inconsiderate", "insensitive", "intolerant", "judgmental", "misogynistic", "nphobic", "oppressive", "pathetic", "patriarchal", "racist", "rape-culture-supporting", "worthless"], # phobias...
      nouns => ["MRA", "TERF", "ableist", "ageist", "anti-feminist", "asshole", "assimilationist", "basement dweller", "bigot", "binarist", "brogrammer", "carnist", "chauvinist", "cissexist", "classist", "cracker", "creep", "dudebro", "essentialist", "fascist", "feminazi", "femscum", "hitler", "kyriarchist", "loser", "lowlife", "misogynist", "mouthbreather", "nazi", "neckbeard", "oppressor", "patriarchist", "pedophile", "piece of shit", "radscum", "rape-apologist", "rapist", "redditor", "scum", "sexist", "shit stain", "singletist", "subhuman", "traditionalist", "transmisogynist", "troll", "truscum", "virgin"]
    },
    intros => ["can we talk about this?", "first off:", "for the love of god.", "girl, please.", "i don't [fucking] care anymore.", "i don't even.", "i'm going to get hate for this but", "just a friendly reminder:", "just... stop.", "let me make this [abundantly] clear:", "no. just no.", "oh. my. god.", "omg", "please [fucking] stop.", "seriously?", "this. is. NOT. okay.", "wow. just. wow.", "you know what? fuck it."],
    rawKins => ["cat", "demon", "dog", "dolphin", "dragon", "fox", "goat", "other", "poly", "rabbit", "wolf"],
    kins => ["catkin", "demonkin", "dogkin", "dolphinkin", "dragonkin", "foxkin", "goatkin", "otherkin", "polykin", "rabbitkin", "wolfkin"],
    marginalized => {
      verbs => [
        ["abuse", "abusing", "abuse"],
        ["attack", "attacking", "attacking"],
        ["criticize", "criticizing", "criticization"],
        ["dehumanize", "dehumanizing", "dehumanization"],
        ["deny", "denying", "denial"],
        ["desexualize", "desexualizing", "desexualization"],
        ["discriminate", "discriminating", "discrimination"],
        ["erase", "erasing", "erasure"],
        ["exotify", "exotifying", "exotification"],
        ["exploit", "exploiting", "exploitation"],
        ["fetishize", "fetishizing", "fetishization"],
        ["harass", "harassing", "harassment"],
        ["hypersexualize", "hypersexualizing", "hypersexualization"],
        ["ignore", "ignoring", "ignoring"],
        ["kinkshame", "kinkshaming", "kinkshaming"],
        ["label", "labeling", "labeling"],
        ["marginalize", "marginalizing", "marginalization"],
        ["misgender", "misgendering", "misgendering"],
        ["objectify", "objectifying", "objectification"],
        ["oppress", "oppressing", "oppression"],
        ["reject", "rejecting", "rejection"],
        ["sexualize", "sexualizing", "sexualization"],
        ["shame", "shaming", "shaming"],
        ["stare-rape", "stare-raping", "stare-raping"],
        ["stigmatize", "stigmatizing", "stigmatization"]
      ],
      nouns => ["CAFAB", "CAMAB", "PoC", "QTPOC", "WoC", "ace", "agnostic", "ally", "amputee", "atheist", "cross-dresser", "equalist", "fatty", "female", "feminist", "freeganist", "furry", "headmate", "ladytype", "little person", "minority", "native american", "princex", "radfem", "survivor", "transman", "transnormative", "transwoman", "vegan", "vegetarian", "victim", "womyn", "wymyn"],
      adjectives => ["LGBTQIAP+", "androgyne", "androphile", "asian", "bear", "bi", "black", "celestial", "chubby", "closet", "curvy", "dandy-femme", "deathfat", "demi", "differently abled", "disabled", "ethnic", "fat", "femme", "freebleeding", "genderfluid", "genderfuck", "genderless", "genderqueer", "gynephile", "hijra", "latino","latina", "metrosexual", "multigender", "non-gender", "non-white", "obese", "queer", "skinny", "smallfat", "therian", "thin", "third-gender", "trans*", "transabled", "two-spirit", "underprivileged"],
    },
    personalities => [
      ["", "-aligned", "-associating", "-identifying", "-type", "-supporting"],
      ["individuals", "people", "personalities", "spirits"]
    ],
    activism => [
      ["anti-porn", "anti-feminism", "body-positivity", "environmental", "fat rights", "gay rights", "gay", "lesbian", "men's rights", "social justice", "trans*", "animal rights"],
      ["activist", "separatist", "warrior"]
    ],
    ists => [
      ["", "cyber", "gay", "lesbian", "liberal", "radical", "sex-positive", "male", "intersectional"],
      ["agnostic", "atheist", "communist", "egalitarianist", "equalist", "feminist", "leftist", "liberationist", "masculinist", "misandrist", "nihilist", "nationalist", "socialist", "womanist"]
    ],
    politics => {
      nouns => ["anti-SJW", "conservative", "democrat", "dyke", "freedom fighter", "freegan", "liberal", "libertarian", "misanthrope", "pro-choice", "pro-life", "republican", "vegan", "women's liberationist", "zapatista"],
    },
    presentations => ["fighting {concepts.terrible} / fighting {concepts.terrible} / fighting {concepts.terrible}", "i am fighting against {concepts.terrible} and {privileged.nouns} privileges", "i am fighting for {concepts.awesome} and {marginalized.nouns} rights", "i am part {rawKins}kin/{rawKins}kin with some {rawKins} traits", "i blog about {concepts.awesome}", "i identify as a {marginalized.nouns} spirit", "if you think {concepts.terrible} is a good thing {insults.statements}", "if you're a {insults.nouns} {insults.statements}", "my pronuns are {joinedPronouns} or {joinedPronouns}", "my triggers include {triggers}", "please don't talk to me about {concepts.terrible}, it's incredibly triggering to me"],
    joinedPronouns => ["ey/em/eir","tho/thong/thors","hu/hum/hus","thon/thon/thons","jee/jem/jeir","Ive/ver/vis","xe/xem/xyr","ze/zir/zes","ze/hir/hir","ze/mer/zer","zhe/zhim/zher"],
    revolutions => ["aceo", "black", "chubby", "curvy", "deathfat", "demi", "diversity", "dysphoria", "ethnicity", "fandom", "fat", "fatty", "fem", "furry", "height", "homo", "latin", "lesb", "queer", "skinny", "trans", "womyn", "wymyn"],
    statementToldYouTo => ["how [can it be|is it] so [fucking] difficult to", "how [fucking] difficult is it to just", "how often do I have to tell you to", "i've [already|repeatedly] told you to", "is it so fucking difficult to", "why can't you just", "why is it so hard for you to", "you should"],
    statements => ["[acknowledge|check] your [fucking] {privileged.nouns} privilege!",'[currently|right now|today|this week|this month] i\'m [literally] [{alignments}|a {kins}], so [fucking] address me as "{joinedPronouns}" and not "{joinedPronouns}"!',"[fuck|screw] [everything about] {concepts.terrible}!","[fuck|screw] your [fucking|goddamn|] {concepts.terrible}!", "[fuck|screw] your {marginalized.verbs} of {marginalized.adjectives}{personalities}!", "[people|{insults.adjectives} {insults.nouns#pluralize}] like you deserve to [fucking] die!", "[{statementToldYouTo}] [accept|acknowledge|respect] that i'm [literally] [{alignments}|a {kins}] [today|this week|this month]!", "[{statementToldYouTo}] [accept|acknowledge|respect] that {concepts.terrible} is [incredibly] [fucking] [annoying|problematic]!", "[{statementToldYouTo}] [accept|acknowledge|respect] that {concepts.terrible} keeps me from having any [fucking|goddamn|damn] rights!", "[{statementToldYouTo}] [accept|acknowledge|respect] that {triggers} is [literally] [a trigger for|triggering|incredibly triggering to] me!", '[{statementToldYouTo}] [respect that|accept that|acknowledge that|] my pronouns are "{joinedPronouns}"!',"[{statementToldYouTo}] [show some respect for|accept|respect|acknowledge] {concepts.awesome}!","[{statementToldYouTo}] [stop|quit] [offending|tone policing|triggering] me!", "[{statementToldYouTo}] [stop|quit] {marginalized.verbs} {marginalized.adjectives}{personalities}!", "[{statementToldYouTo}] [stop|quit] {marginalized.verbs} {marginalized.adjectives}{personalities}!",'[{statementToldYouTo}] [fucking] address me as "{joinedPronouns}"!', "[{statementToldYouTo}] leave {marginalized.adjectives}{personalities} [the fuck] alone!", "all {insults.adjectives} {insults.nouns#pluralize} can [fucking] [go to|burn] in hell!", "can we [please] just have a post about {marginalized.adjectives} {marginalized.nouns#pluralize} that doesn't get co-opted by [fucking] {privileged.nouns}-{privileged.adjectives} people?", "consensual sex|PIV intercourse] is [still|always] [fucking] rape!", "don't [talk about|mention] [fucking] {triggers}, it's [incredibly|terribly|really|literally|] triggering to me!", "don't you see [that|how] {marginalized.verbs} {marginalized.adjectives}{personalities} is problematic?", "get off my [fucking|goddamn|damn|] case or i'll [literally] report you for [harassment|{marginalized.verbs} of {marginalized.adjectives}{personalities}]!", "i [literally] don't need your [fucking|goddamn|worthless|problematic] advice!", "i [literally] hope you [fucking] [die|die in a fire|bleed to death]!", "i [literally] hope your [fucking] asshole prolapses!", "i'm [literally] crying right now!", "it's [literally] not my [fucking|goddamn|damn|] job to educate you!", "no one cares about your [fucking|goddamn|damn|] {insults.nouns} {privileged.nouns} opinion!", "oh my [fucking] god!", "what the [fuck|hell] do you have against {concepts.awesome}?", "why [the fuck|the hell|] do you [feel the need to] {marginalized.verbs} {marginalized.adjectives}{personalities}?", "why [the fuck|the hell|] should i [accept|respect|acknowledge] your [fucking|goddamn|damn|{insults.adjectives}|] {insults.nouns} opinion?", "you [literally] make me [fucking] sick!", "you can be a {marginalized.adjectives} {marginalized.nouns} and still have [some] {privileged.nouns} [fucking] privilege!", "you should [stop|quit] {marginalized.verbs} {marginalized.adjectives}{personalities}!", "you should be [fucking] ashamed of yourself!", "you'll [literally] never understand my [fucking|goddamn|damn|] {marginalized.adjectives} {marginalized.nouns} [struggles|issues]!", "you're [literally] [making me cry|triggering me|the worst person alive|worse than hitler]!", "you're [literally] perpetuating {concepts.terrible}!", "your [fucking|damn|goddamn|] {insults.nouns} {privileged.nouns}-privileged opinion[ is|s are] [literally] [fucking] worthless!", "your {marginalized.verbs} of {marginalized.adjectives}{personalities} is [really|very|] problematic!", "{statementToldYouTo} [fucking] [accept|acknowledge|respect] that you can be fat and healthy!", "{statementToldYouTo} [fucking] [accept|respect|acknowledge] {concepts.awesome}?"],
    titles => ["erasing {concepts.terrible}", "fighting {concepts.terrible}", "social justice and {concepts.awesome}", "this is social justice", "this is {privileged.nouns} privilege", "{marginalized.nouns} microaggressions", "{marginalized.nouns} {concepts.awesome}", "{privileged.nouns} crimes", "{privileged.nouns} tears", "{revolutions}"],
    triggers => [["appearance", "color", "fat", "femininity", "gender", "non-gender", "non-sexuality", "obesity", "sexuality", "thin", "weight loss"], ["appropriation", "culture", "exotification", "hate", "labels", "opinions", "shaming", "standards"]]

  },
  'commands' => {
    '^Insult$' => {
      'cooldown' => 2,
      'description' => "Generates a tumblr inspired insult.",
      'code' => sub { $utility{'Fancify_say'}($_[1]{irc},$_[2]{where},$utility{'Insult_tumblr'}(0,1)); }
    },
    '^Insult (.+)$' => {
      'cooldown' => 2,
      'description' => "Generates a tumblr inspired insult towards someone.",
      'code' => sub { my $target = $1; $utility{'Fancify_say'}($_[1]{irc},$_[2]{where},$utility{'Insult_tumblr'}(0,1,$target)); }
    },
    '^Rant$' => {
      'cooldown' => 3,
      'description' => "Generates a tumblr inspired rant.",
      'code' => sub { $utility{'Fancify_say'}($_[1]{irc},$_[2]{where},$utility{'Insult_tumblr'}(1)); }
    },
  }
});
