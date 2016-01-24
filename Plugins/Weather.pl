addPlug('Weather', {
  'creator' => 'Caaz',
  'version' => '1',
  'description' => "Gets weather information from Open Weather Map.",
  'name' => 'Weather',
  'dependencies' => ['Fancify'],
  'modules' => ['LWP::Simple'],
  'utilities' => {
    'get' => sub {
      # Input: Location
      # Output: Weather information.
      my $content = get('http://api.openweathermap.org/data/2.5/weather?q='.$_[0]);
      return ($content)?decode_json($content):{'message'=>"Error: Couldn't get information."};
    },
    'show' => sub {
      # Input: Handle, Where, Weather
      my %weather = %{$_[2]};
      &{$utility{'Fancify_say'}}($_[0],$_[1],($weather{message})?$weather{message}:"\x04$weather{name}, $weather{sys}{country}\x04: [Temperature: \x04".int($weather{main}{temp}*9/5-459.67)."F\x04/\x04".int($weather{main}{temp}-273.15)."C\x04] [Humidity: \x04$weather{main}{humidity}\x04\%] ");
    }
  },
  'commands' => {
    '^W(?:eather)? (.+)' => {
      'description' => "Gets weather information for some location.",
      'code' => sub { $loc = $1; $utility{'Weather_show'}($_[1]{irc},$_[2]{where},$utility{'Weather_get'}($loc)); }
    }
  }
});