#!/usr/bin/perl 
# convert language JSON files into one spreadsheet

# !! !! !! Change this to be the second column's header text in each worksheet !! !! !!
my $DEST_LANG = "Welsh";
my $SRC_LANG = "UK English";

use strict;
use warnings;
use v5.16;
use JSON qw (decode_json);
use Data::Dumper;

# cpan mods
use Excel::Writer::XLSX;

# globals
my $workbook;
my ($targetXls, @sourceJsons);

my $BANNER = << 'EOF';
JSON files to a single Excel workbook. Author: MJB. (14/12/21)
Takes a destination file name then list of JSON files. Will write each file
as worksheets inside the destination excel workbook.

Usage:
./jsontoxls.pl <target>.xlsx <source>.json *

Eg, ./jsontoxls.pl welsh.xlsx common.json timetables.json glossary.json
Will produce welsh.xlsx with worksheets named after each.
EOF

# args - JSON file name without extension
sub read_json_file {
    my $jsonf = shift;
    my $jsonf_txt;
    my $fh;

    open $fh, '<', "$jsonf" or die "Cannot read '$jsonf': $!\n";
    $jsonf_txt .= $_ while <$fh>;

    my $json = decode_json($jsonf_txt);
    #say Dumper($json);

    my %json_hsh = %{$json};

    close $fh;
    #say "KEYS:" . keys (%json_hsh);
    #say Dumper(%json_hsh);
    return \%json_hsh;
}


# args - worksheet name, hashref of json file
# works on global object
sub write_worksheet {
    my $ws_name = shift;
    my $hashref = shift;

    my %json_hsh = %{$hashref};

    my $worksheet = $workbook->add_worksheet($ws_name);

    my ($row, $col);
    $row = $col = 0;
    $worksheet->write( $row, $col, $SRC_LANG);
    $col = 1;
    $worksheet->write( $row, $col, $DEST_LANG );
    
    $row = 1;
    for my $key (keys %json_hsh) {
        $col = 0;
        $worksheet->write($row, $col, $key);
        $col = 1;
        $worksheet->write($row, $col, $json_hsh{$key});
        $row++;
    }
}

# Begin exec, read args array
die ($BANNER) if (scalar @ARGV < 2);
($targetXls, @sourceJsons) = @ARGV;

# init excel writer
$workbook = Excel::Writer::XLSX->new( $targetXls );
die "Problems creating new Excel file: $!" unless defined $workbook;

# read each json file & write it into our workbook
for my $srcJsonFile (@sourceJsons) {
    die "filename not found: $srcJsonFile " unless -f $srcJsonFile;
    print "Reading $srcJsonFile";
    (my $worksheet_name = $srcJsonFile) =~ s/\.json//;
    print " into worksheet $worksheet_name...";

    my %jsonHsh = %{ read_json_file($srcJsonFile) };
    write_worksheet($worksheet_name, \%jsonHsh);
    print " and it's done\n";
}
say "Process complete. Results are in $targetXls";

$workbook->close();
