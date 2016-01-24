addPlug('IMDB', {
  name => 'IMDB Search',
  description => "This is a plugin to access the api at omdbapi.com",
  creator => 'Caaz',
  version => '1',
  modules => ['LWP::Simple'],
  dependencies => ['Fancify', 'Core_Utilities'],
  utilities => {
    'search' => sub {
      #Input: Handle, Where, Search, Limit, include plot?
      #Output: Hash of Results
      my $searchPage = get('http://www.omdbapi.com/?s='.$_[2]);
      $searchPage =~ s/[!\P{IsASCII}]/-/g;
      %results = %{decode_json($searchPage)};
      &{$utility{'Core_Utilities_debugHash'}}(\%results);
      if($results{'Error'}) {
        &{$utility{'Fancify_say'}}($_[0],$_[1],$results{'Error'});
        return 0;
      }
      my $i = 0;
      foreach(@{$results{'Search'}}) {
        my $content = get('http://www.omdbapi.com/?i='.${$_}{imdbID});
        $content =~ s/[!\P{IsASCII}]/-/g;
        %imdb = %{decode_json($content)};
        if($imdb{Title} =~ /^$_[2]$/i) {
          if(!$_[4]) {
            my @genres = split /, /, $imdb{Genre};
            foreach(@genres) { $_ = substr($_, 0, 3); }
            &{$utility{'Fancify_say'}}($_[0],$_[1],"[http://www.imdb.com/title/$imdb{imdbID}] [\x04$imdb{Title}\x04 $imdb{Year}] [\x04$imdb{imdbRating}\x04/\x0410\x04] [\x04".(join "\x04, \x04", @genres)."\x04] [\x04$imdb{Runtime}\x04]");
          }
          else {
            &{$utility{'Fancify_say'}}($_[0],$_[1],"[http://www.imdb.com/title/$imdb{imdbID}] [\x04$imdb{Title}\x04 $imdb{Year}] [\x04$imdb{Genre}\x04] [\x04$imdb{imdbRating}\x04/\x0410\x04 from \x04$imdb{imdbVotes}\x04 votes] [\x04$imdb{Runtime}\x04] $imdb{Plot}");
          }
          $i++; if((!$_[3]) || ($i > $_[3])) { return 1; }
        }
      }
      &{$utility{'Fancify_say'}}($_[0],$_[1],"Nothing found that matched.");
      return 0;
    },
  },
  commands => {
    '^IMDB (.+)$' => {
      cooldown => 3,
      code => sub {
        my $search = $1;
        if($_[2]{where} =~ /moonspace$|testopia$/i) { &{$utility{'IMDB_search'}}($_[1]{irc},$_[2]{where},$search,2,0); }
        else { &{$utility{'IMDB_search'}}($_[1]{irc},$_[2]{where},$search,0,1); }
      }
    }
  },
});