#!/usr/bin/perl 
# translate language JSON file into another 
# Requires: Google translate API key

# !! !! !! CHANGE TO YOUR API KEY !! !! !! =>
my $G_TRANSLATE_API_KEY = "??";

# pragmas
use v5.20;
use strict;
use warnings;
use JSON qw (decode_json encode_json);
use Data::Dumper;
use feature qw(signatures);
no warnings qw(experimental::signatures);

# cpan modules (required)
use WWW::Google::Translate;

# global vars
my ($sourceJson, $targetJson, $lngCode, $parsedSourceRef, $translationResultRef, $encodedJson);
my $wgt;

my $BANNER = << 'EOF';
JSON keys to Google translate. Author: MJB. (22/12/21)
Will take JSON key values in a <source> file and run them through Gtranslate.
The result is written to <target>.

Usage:
./gtranslate.pl <source>.json <target>.json <language code>

Eg, ./gtranslate.pl common.json es/common.json es-ES
EOF

# args - JSON file name 
sub read_json_file ($jsonf) {
    my $jsonf_txt;
    my $fh;

    open $fh, '<', "$jsonf" or die "Cannot read '$jsonf': $!\n";
    $jsonf_txt .= $_ while <$fh>;

    my $json = decode_json($jsonf_txt);
    die "Problem parsing JSON in $jsonf: $!" if ($!);

    my %json_hsh = %{$json};

    close $fh;
    return \%json_hsh;
}

# args - parsed source JSON hashref
# returns - ref to duplicate hash with results
sub run_translation ($parsedSourceRef) {
    # construct result hash, deref and copy source language hash
    my %results = %{$parsedSourceRef};
    my $total = keys %results;

    say "Translating a total of $total";

    for my $key (sort keys %results) {
        print "REQUEST: $key";
        my $r = $wgt->translate( { q => $key } );
        my $resp = $r->{data}->{translations}->[0]->{translatedText};
        $results{$key} = $resp;
        print "RESPONSE: $results{$key}\n";
    }

    return \%results;
}

# Begin exec, read args array
die ($BANNER) if (scalar @ARGV < 3);
($sourceJson, $targetJson, $lngCode) = @ARGV;

$parsedSourceRef = read_json_file($sourceJson);
say "Read of source OK. Instaniating Google translate.";

# init google
$wgt = WWW::Google::Translate->new(
    {   key            => $G_TRANSLATE_API_KEY,
        default_source => 'en',   # optional
        default_target => $lngCode,   # optional
    }
);
die "Couldn't create gtranslate object" unless defined $wgt;
 
# run translation
say "Running translation. Source file: $sourceJson. Language code: $lngCode"; 
$translationResultRef = run_translation ($parsedSourceRef);

say "Translation success. Writing to destination: $targetJson." ;
$encodedJson = encode_json( $translationResultRef );
#say $encodedJson;
open my $fh, ">", $targetJson or die "Could not open $targetJson for writing";
print $fh $encodedJson;
close $fh;

say "Complete.";
