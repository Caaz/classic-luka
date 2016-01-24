addPlug("xkcd", {
  'creator' => 'Caaz',
  'version' => '1',
  'name' => 'xkcd',
  'dependencies' => ['Core_Utilities'],
  'modules' => ['HTML::Entities', 'LWP::Simple'],
  'utilities' => {
    'get' => sub {
      # Input: Handle, Channel, Comic ID.
      lkDebug("got $_[2] - ".'https://xkcd.com/'.$_[2].'/info.0.json');
      my %comic = (num => '-1', alt => "Something went wrong.", img => "N/A");
      %comic = %{decode_json(get('https://xkcd.com/'.$_[2].'/info.0.json'))} if($_[2]);
      %comic = %{decode_json(get('https://xkcd.com/info.0.json'))} if(!$_[2]);
      &{$utility{'Core_Utilities_debugHash'}}(\%comic);
      #if($comic{transcript}) { &{$utility{'Fancify_say'}}($_[0],$_[1],"[#$comic{num} $comic{img}] $comic{transcript}"); }
      #else { &{$utility{'Fancify_say'}}($_[0],$_[1],"[#$comic{num} $comic{img}] $comic{alt}"); }
      my $string = "[#$comic{num} ";
      $string .= $comic{link} if($comic{link});
      $string .= $comic{img} if(!$comic{link});
      $string .= "] $comic{alt}";
      &{$utility{'Fancify_say'}}($_[0],$_[1],$string);
      return 1;
    }
  },
  'commands' => {
    '^xkcd$' => {
      'description' => "Fetches the latest xkcd image.",
      'code' => sub {
        &{$utility{'xkcd_get'}}($_[1]{irc},$_[2]{where});
      }
    },
    '^xkcd (\d+)$' => {
      'description' => "Fetches an xkcd image by number.",
      'code' => sub {
        my $id = $1;
        lkDebug('Doing '.$id);
        &{$utility{'xkcd_get'}}($_[1]{irc},$_[2]{where},$id);
      }
    }
  }
});