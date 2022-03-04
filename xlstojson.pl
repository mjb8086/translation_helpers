#!/usr/bin/perl 
# convert language workbook file into many JSON

# !! !! !! Enable this to skip headers in each worksheet !! !! !!
my $SKIP_FIRST_ROW = 1;

use strict;
use warnings;
use v5.20;
use JSON;
use Data::Dumper;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use Encode qw(encode_utf8);

# cpan mods
use Spreadsheet::ParseXLSX;

# globals
my ($sourceXls, $workbook, $parser, $json);

# Create JSON encoder object, set pretty print and sort output
$json = JSON->new->allow_nonref;
$json->pretty([1]);
$json->canonical([1]);

my $BANNER = << 'EOF';
Convert excel worksheets into JSON files. Author: MJB. (23/12/21)
<source>.clsx will be read and parsed for worksheets. Each of the first two
cells in each column will be treated as key:value in JSON.
Each worksheet name will be used made into its own JSON file.

Usage:
./xlstojson.pl <source>.xlsx

Eg, ./xlstojson.pl welsh.xlsx 
Will produce a JSON file for each worksheet inside welsh.xlsx
EOF

# args - JSON file name, ref to key:value hash
sub write_json_file($jsonfn, $hashref) {
    my $fh;

    open $fh, '>', "$jsonfn" or die "Cannot write '$jsonfn': $!\n";

    my $jsonTxt = $json->encode( $hashref );
    #    die "Couldn't encode JSON: $!" if $!;

    say "Writing to $jsonfn";
    print $fh encode_utf8("$jsonTxt");
    close $fh;
}


# Begin exec, read args array
die ($BANNER) if (scalar @ARGV != 1);
($sourceXls) = @ARGV;

# init excel reader
$parser = Spreadsheet::ParseXLSX->new;
$workbook = $parser->parse($sourceXls);
die "Problems parsing Excel file: $!" unless defined $workbook;

# read each worksheet 
for my $worksheet ( $workbook->worksheets() ) {
    my %wsHash;
    my $wsName = $worksheet->get_name();
    my ($rowMin, $rowMax) = $worksheet->row_range();

    say "Reading worksheet $wsName";
    for my $row ( $rowMin .. $rowMax ) {
        next if ($row == 0 && $SKIP_FIRST_ROW);
        my $cell0 = $worksheet->get_cell($row, 0);
        next unless $cell0;
        my $cell1 = $worksheet->get_cell($row, 1);
        next unless $cell1;
        $wsHash{ $cell0->value() } = $cell1->value();
    }
    write_json_file("${wsName}.json", \%wsHash);
}
say "Process complete.";

