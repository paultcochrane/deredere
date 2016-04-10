use v6;

use HTTP::UserAgent;
use Gumbo;

unit module deredere;

# Scraper instances.
multi sub scrap(Str $url) is export {
    default-save-operator(get-page($url), $url);
}

multi sub scrap(Str $url, &parser, Str :$filename="scraped-data.txt") is export {
    my $page = get-page($url);
    my $xml = parse-html($page.content);
    my @data = &parser($xml);
    default-save-operator(@data, $filename);
}

multi sub scrap(Str $u, &parser, &next, &operator, Int $gens=1) is export {
    my $page;
    my $xml;
    my $url = $u;
    for (1 .. $gens) {
	$page = get-page($url);
	$xml = parse-html($page.content);
	&operator(&parser($xml));
	$url = &next($xml);
    }
}

# Operators.
multi sub default-save-operator($res, $url) {
    my $name = split("/", $url)[*-1];
    # We need to somehow distinguish bad and good url ends...
    unless $name.ends-with(".html"|".htm"|".xhtml"|".jpg"|".png"|".jpeg") {
    	$name ~= ".html";
    }

    if $res.is-binary {
	spurt $name, $res.content, :bin;
    } else {
	spurt $name, $res.content;
    }
}

multi sub default-save-operator(@data, Str $filename) {
    my @data-pull;
    # .race here is optional. I gained a small speed improvement by this
    # even on small(10-20 links) pulls, but testing with a wide bandwith
    # and many variants is still needed to decide is we really need .race here.
    @data.race.map( { if $_.starts-with("http://") {
			    default-save-operator(get-page($_), $_);
			} else {
			  @data-pull.append($_);
		      }});
    if @data-pull.defined {
	my $fh = open $filename, :a;
	for @pull {
	    $fh.say($_);
	}
	$fh.close;
    }
}

# Utilites.
our sub get-page(Str $url, Int $timeout=10) {
    my $ua = HTTP::UserAgent.new(:useragent<chrome_linux>);
    $ua.timeout = $timeout;
    $ua.get($url);
}