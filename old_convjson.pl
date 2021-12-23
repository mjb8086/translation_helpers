#!/usr/bin/perl 
# convert language JSON files into one workbook
# very rigid, needs args...

use strict;
use warnings;
use v5.16;
use JSON qw (decode_json);
use Data::Dumper;
use utf8;

# cpan mods
use Excel::Writer::XLSX;

# globals
my $workbook;

# args - JSON file name without extension
sub read_json_file {
    my $jsonf = shift;
    my $jsonf_txt;
    my $fh;

    open $fh, '<', "$jsonf.json" or die "Cannot read '$jsonf': $!\n";
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
    $worksheet->write( $row, $col, 'UK English');
    $col = 1;
    $worksheet->write( $row, $col, 'Welsh' );
    
    $row = 1;
    for my $key (keys %json_hsh) {
        $col = 0;
        $worksheet->write($row, $col, $key);
        $col = 1;
        $worksheet->write($row, $col, $json_hsh{$key});
        $row++;
    }
}

my $excelfile = "welsh.xlsx";

$workbook = Excel::Writer::XLSX->new( $excelfile );
die "Problems creating new Excel file: $!" unless defined $workbook;

my %common = %{ read_json_file("common") };
write_worksheet("common", \%common);

my %glossary = %{ read_json_file("glossary") };
write_worksheet("glossary", \%glossary);

my %profile = %{ read_json_file("profile") };
write_worksheet("profile", \%profile);

my %timetables = %{ read_json_file("timetables") };
write_worksheet("timetables", \%timetables);

$workbook->close();
