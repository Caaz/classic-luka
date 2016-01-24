addPlug('Mnn', {
  name => 'mnn.im API',
  description => "This is a plugin to access the mnn.im API!",
  creator => 'Caaz',
  version => '1',
  modules => ['LWP::UserAgent'],
  dependencies => ['Fancify', 'Core_Utilities'],
  utilities => {
    'shorten' => sub {
      return $_[0];
      my $ua = LWP::UserAgent->new();
      my %result;
      eval { %result = %{decode_json($ua->post('http://mnn.im/s',Content=>$_[0])->decoded_content())}; };
      if($@) { return $_[0]; }
      else { return ($result{status} eq 'success')?$result{url}{short_url}:$_[0]; }
    },
  },
  commands => {
    '^Shorten (.+)$' => {
      cooldown => 3,
      code => sub {
        my $url = $1;
        &{$utility{'Fancify_say'}}($_[1]{irc},$_[2]{where},"Your shortened URL is ".&{$utility{'Mnn_shorten'}}($url));
      }
    }
  },
});